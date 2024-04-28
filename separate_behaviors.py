import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

# Load the data from the CSV file
data_path = "page_views.csv"
data = pd.read_csv(data_path)

# Display the first few rows of the data to understand its structure
data.head()

# Convert the 'was_complete' to boolean
data['was_complete'] = data['was_complete'].astype(bool)

grouped_data = data.groupby(['book', 'chapter_number', 'section_number','institution_id', 'class_id', 'page', 'student_id'])['engaged'].sum().reset_index()
filtered_data = grouped_data[grouped_data['engaged'] > 0]
filtered_data['log_engaged'] = np.log10(filtered_data['engaged'])


# plt.figure(figsize=(10, 6))
# sns.histplot(filtered_data['log_engaged'], kde=True, binwidth=0.1)  # Adjusted bin width for log scale
# plt.title('Log-Scaled Distribution of Total Engagement Time for All Pages')
# plt.xlabel('Log10 of Engagement Time (ms)')
# plt.ylabel('Frequency')
# plt.grid(True)
# plt.show()

percentile_33 = np.percentile(filtered_data['log_engaged'], 33)
percentile_66 = np.percentile(filtered_data['log_engaged'], 66)

def categorize_reading(log_engaged):
    if log_engaged < percentile_33:
        return 'Fast Reading'
    elif log_engaged < percentile_66:
        return 'Medium Reading'
    else:
        return 'Slow Reading'

# Apply categorization function to the DataFrame
filtered_data['reading_speed'] = filtered_data['log_engaged'].apply(categorize_reading)

# Calculate average engagement time in milliseconds for each category
average_times = filtered_data.groupby('reading_speed')['engaged'].mean().reset_index()

# Group by student, book, chapter number, and calculate the total reading time per chapter for each student
total_time_per_chapter = filtered_data.groupby(['student_id', 'book', 'chapter_number'])['engaged'].sum().reset_index()

# Log-scale the total times
total_time_per_chapter['log_total_engaged'] = np.log10(total_time_per_chapter['engaged'])

# Plotting the distribution of these log-scaled total engagement times per chapter
plt.figure(figsize=(10, 6))
sns.histplot(total_time_per_chapter['log_total_engaged'], kde=True, binwidth=0.1)
plt.title('Distribution of Log-Scaled Total Reading Time per Chapter')
plt.xlabel('Log10 of Total Engagement Time per Chapter (ms)')
plt.ylabel('Frequency')
plt.grid(True)
plt.show()

