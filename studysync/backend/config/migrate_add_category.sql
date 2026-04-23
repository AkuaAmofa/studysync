-- Run once to add the category column used for filter chips
ALTER TABLE ss_study_groups
  ADD COLUMN category VARCHAR(50) NULL AFTER course_name;
