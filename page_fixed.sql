SET search_path TO datafest_full;
-- classify student as fast, average, or slow reader based on their average engaged time
-- engaged time is the sum of time spent on each page in a section
-- engaged time is log transformed to normalize the distribution

-- student's total engaged time in a page

DROP VIEW IF EXISTS page_correct_rate CASCADE;
DROP VIEW IF EXISTS page_engagement CASCADE;
DROP VIEW IF EXISTS student_behavior_cat CASCADE;
DROP VIEW IF EXISTS student_behavior CASCADE;
DROP VIEW IF EXISTS student_response CASCADE;
DROP VIEW IF EXISTS page_views_log CASCADE;


-- get all the student's total engaged time in a chapter and the distint number of pages they read
CREATE view total_views AS
SELECT 
    student_id,
    SUM(engaged) AS engaged_time,
    COUNT(DISTINCT page) AS num_pages,
    SUM(engaged) / COUNT(DISTINCT page) AS avg_engaged_time,
    LOG(SUM(engaged) / COUNT(DISTINCT page)) AS log_avg_engaged_time
FROM
    page_views
GROUP BY
    student_id
ORDER BY
    student_id;



-- i want to get the 33% and 66% quantile of the log transformed engaged time
-- so that i can classify students as fast, average, or slow reader based on their average engaged time
CREATE view engaged_time_quantile AS
SELECT 
    PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY log_avg_engaged_time) AS q1,
    PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY log_avg_engaged_time) AS q2
FROM
    total_views;

-- classfiy student as fast, average, or slow reader based on their average engaged time and the quantile
CREATE view student_group AS
SELECT 
    student_id,
    engaged_time,
    CASE 
        WHEN log_avg_engaged_time <= (SELECT q1 FROM engaged_time_quantile) THEN 'Fast Reader'
        WHEN log_avg_engaged_time > (SELECT q1 FROM engaged_time_quantile) and  log_avg_engaged_time <= (SELECT q2 FROM engaged_time_quantile) THEN 'Average Reader'
        ELSE 'Slow Reader'
    END AS engagement_category
FROM
    total_views
ORDER BY
    student_id;

-- give number of student in each group
CREATE view student_group_count AS
SELECT 
    engagement_category,
    COUNT(*) AS num_students
FROM
    student_group
GROUP BY
    engagement_category
ORDER BY
    engagement_category;


-- find the last attempt of each student in each item
-- the last attempt is the attempt with the highest attempt number

CREATE view student_response AS
WITH last_attempt AS (
    SELECT 
        student_id,
        item_id,
        MAX(dt_submitted) AS last_submission_time
    FROM 
        responses
    WHERE 
        review_flag = FALSE
    GROUP BY 
        student_id, item_id
),
last_response AS (
    SELECT 
        rs.page,
        rs.student_id,
        rs.item_id,
        rs.points_possible,
        rs.points_earned,
        rs.dt_submitted,
        rs.attempt
    FROM 
        responses rs
    JOIN 
        last_attempt la ON rs.student_id = la.student_id AND rs.item_id = la.item_id AND rs.dt_submitted = la.last_submission_time
    WHERE 
        rs.review_flag = FALSE
)
SELECT DISTINCT
    page,
    student_id,
    item_id,
    points_possible,
    points_earned,
    dt_submitted,
    attempt
FROM 
    last_response
ORDER BY 
    student_id, page, item_id;

-- find the average score of each student in each page by summing up the points earned and points possible
-- and dividing the sum by the number of items in the page

CREATE view student_bahavior AS
SELECT 
    student_id,
    page,
    sum(points_earned) / sum(points_possible) AS avg_score
FROM
    student_response
GROUP BY
   student_id,page
ORDER BY
    student_id, page;

-- find the page engaged time of each student by summing up the engaged time of each page
CREATE view page_views_student AS
SELECT 
    student_id,
    page,
    sum(engaged) AS total_engaged_time
FROM
    page_views
GROUP BY
    student_id, page
ORDER BY
    student_id, page;

-- JOIN student behavior with page views log

CREATE view student_behavior_cat AS
SELECT 
    pb.page,
    pb.student_id,
    pb.avg_score,
    pv.engagement_category
FROM
    student_bahavior pb
JOIN
    student_group pv ON pb.student_id = pv.student_id
ORDER BY
    pb.student_id, pb.page;


-- join the page views student with the student behavior cat  
-- to get the total engaged time of each student in each page
CREATE view student_final AS
SELECT 
    sb.page,
    sb.student_id,
    sb.avg_score,
    sb.engagement_category,
    pvs.total_engaged_time
FROM
    student_behavior_cat sb
JOIN
    page_views_student pvs ON sb.student_id = pvs.student_id AND sb.page = pvs.page
ORDER BY
    sb.student_id, sb.page;


-- Find the average correct rate of each group for each page
CREATE view page_correct_rate AS
SELECT 
    page,
    engagement_category,
    AVG(avg_score) AS avg_correct_rate 
FROM
    student_final
GROUP BY
    page, engagement_category
ORDER BY
    page, engagement_category;

-- Find the average engaged time of each group for each page
CREATE view page_engagement_avg AS
SELECT 
    page,
    engagement_category,
    AVG(total_engaged_time) AS avg_engaged_time
FROM
    student_final
GROUP BY
    page, engagement_category
ORDER BY
    page, engagement_category;

-- join page engagement and page correct rate
SELECT 
    pcr.page,
    pcr.engagement_category,
    pcr.avg_correct_rate,
    pe.avg_engaged_time
FROM
    page_correct_rate pcr
JOIN
    page_engagement_avg pe ON pcr.page = pe.page AND pcr.engagement_category = pe.engagement_category
ORDER BY
    pcr.page, pcr.engagement_category;



