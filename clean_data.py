import pandas as pd

# Load the data
df = pd.read_csv('responses.csv')

# Replace 'NA' with an empty string
df.replace('NA', '', inplace=True)

# Save the cleaned data
df.to_csv('/Users/bluewater/Desktop/DataFest/responses.csv', index=False)