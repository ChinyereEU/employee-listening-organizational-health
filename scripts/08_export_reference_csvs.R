library(readxl)

# File paths
input_file = "data/reference/survey_item_map.xlsx"
output_dir = "data/reference"

# Sheets to export
sheets_to_export = c(
  "Construct_Item_Map",
  "Data_Dictionary",
  "Response_Scales",
  "Change_Log"
)

# Output filenames
output_files = c(
  "construct_item_map.csv",
  "data_dictionary.csv",
  "response_scales.csv",
  "change_log.csv"
)

# Convert each selected sheet to CSV
for (i in seq_along(sheets_to_export)) {
  
  data = read_excel(
    input_file,
    sheet = sheets_to_export[i]
  )
  
  write.csv(
    data,
    file.path(output_dir, output_files[i]),
    row.names = FALSE,
    na = ""
  )
}

message("Selected survey item map sheets exported to CSV.")