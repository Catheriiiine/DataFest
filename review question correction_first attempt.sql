SET search_path TO datafest_full;

DROP VIEW IF EXISTS review_or_not CASCADE;
DROP VIEW IF EXISTS first_attempt CASCADE;

CREATE VIEW review_or_not AS
SELECT chapter_number, page,
       CASE
           WHEN review_flag = 'TRUE' THEN 'TRUE'
           ELSE 'FALSE'
       END AS if_review
FROM items;

CREATE VIEW first_attempt AS
SELECT student_id, page, item_id, MIN(dt_submitted) AS first_dt_submitted
FROM responses
GROUP BY student_id, page, item_id;

SELECT fa.student_id, re.chapter_number AS review_question_chapter, re.page AS review_question_page,
       SUM(r.points_earned) / SUM(r.points_possible) AS review_question_correction
FROM review_or_not re
JOIN first_attempt fa ON re.page = fa.page
JOIN responses r ON fa.page = r.page AND fa.student_id = r.student_id AND fa.first_dt_submitted = r.dt_submitted AND fa.item_id = r.item_id
WHERE re.if_review = 'TRUE'
GROUP BY re.page, re.chapter_number, fa.student_id;
