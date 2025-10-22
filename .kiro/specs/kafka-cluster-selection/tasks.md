# Implementation Plan

- [x] 1. Modify discover_kafka_cluster() function to support multiple cluster selection

  - Locate the `discover_kafka_cluster()` function in `bin/confluent-env-export` (around line 230)
  - Add cluster count check after retrieving cluster list
  - Implement conditional logic: if count == 1, auto-select; if count > 1, show menu
  - _Requirements: 1.5_

- [x] 1.1 Implement interactive cluster selection menu

  - Add menu display loop that iterates through cluster JSON array
  - Format each cluster entry with index, name, ID, cloud, region, and status
  - Use existing color constants (BLUE, CYAN, YELLOW, RESET) and SEARCH emoji
  - Match formatting pattern used in Flink compute pool selection
  - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3_

- [x] 1.2 Implement user input validation and selection logic

  - Add input prompt with valid range display
  - Implement validation loop checking for numeric input within valid range
  - Extract selected cluster from JSON array using zero-based index (choice-1)
  - Display success message with selected cluster name and ID
  - _Requirements: 1.3, 1.4, 2.4, 3.4_

- [x] 1.3 Add error handling for edge cases

  - Ensure existing error handling for CLI failures remains intact
  - Ensure existing error handling for zero clusters remains intact
  - Add warning message for invalid user input with re-prompt logic
  - Verify error messages are consistent with existing patterns
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 1.4 Test the implementation manually
  - Test with single cluster environment (verify auto-selection)
  - Test with multiple cluster environment (verify menu display and selection)
  - Test with invalid inputs (non-numeric, out of range)
  - Test with no clusters (verify error handling)
  - Verify generated .env file contains correct cluster information
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_
