# Implementation Plan

- [x] 1. Add command-line flag parsing for Flink and TableFlow

  - Add `--skip-flink` flag to skip Flink compute pool discovery
  - Add `--skip-tableflow` flag to skip TableFlow discovery
  - Update `parse_args()` function to handle new flags
  - Update `usage()` function to document new flags
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 2. Implement Flink compute pool discovery

  - [x] 2.1 Create `discover_flink_compute_pool()` function

    - Execute `confluent flink compute-pool list -o json` CLI command
    - Parse JSON output to extract compute pool information (id, name, region, cloud)
    - Handle case with no compute pools (log info and return)
    - Handle case with single compute pool (auto-select)
    - Handle case with multiple compute pools (present selection menu)
    - Store selected compute pool details in variables
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 2.2 Add error handling for Flink discovery
    - Handle CLI command failures gracefully
    - Handle JSON parsing errors
    - Log appropriate messages (info, warning, error)
    - Continue execution even if Flink discovery fails
    - _Requirements: 1.4_

- [x] 3. Implement Flink API key creation

  - [x] 3.1 Create `create_flink_api_key()` function

    - Build API key creation command with compute pool resource ID
    - Include descriptive label with script name, timestamp, and pool name
    - Execute `confluent api-key create --resource` command
    - Parse table output to extract API key and secret
    - Store key and secret in variables
    - _Requirements: 2.1, 2.2, 3.1, 3.2_

  - [x] 3.2 Add user interaction for Flink key creation

    - Check `--create-keys` flag for automatic creation
    - Prompt user with `confirm()` if flag not set
    - Skip Flink configuration if user declines
    - Handle dry-run mode with placeholder values
    - _Requirements: 2.3, 2.4, 2.5, 3.4_

  - [x] 3.3 Add error handling for Flink key creation
    - Handle API key creation failures
    - Validate that key and secret were successfully parsed
    - Log success message with key identifier
    - Continue execution if key creation fails
    - _Requirements: 3.3, 3.5_

- [x] 4. Implement TableFlow discovery

  - [x] 4.1 Create `discover_tableflow()` function

    - Execute `confluent environment describe -o json` to get organization ID
    - Extract organization ID from JSON output
    - Generate TableFlow catalog URL using organization ID, environment ID, and region
    - Store organization ID and catalog URL in variables
    - _Requirements: 4.1, 4.2, 4.3_

  - [x] 4.2 Add TableFlow availability checks

    - Check if `--skip-tableflow` flag is set
    - Verify organization ID is available
    - Handle case where TableFlow is not enabled
    - Log appropriate info messages
    - _Requirements: 4.4, 4.5_

  - [x] 4.3 Add error handling for TableFlow discovery
    - Handle CLI command failures
    - Handle missing organization ID
    - Handle JSON parsing errors
    - Continue execution if TableFlow discovery fails
    - _Requirements: 4.4_

- [x] 5. Implement TableFlow API key creation

  - [x] 5.1 Create `create_tableflow_api_key()` function

    - Build API key creation command for TableFlow (environment-scoped)
    - Include descriptive label with script name and timestamp
    - Execute `confluent api-key create` command
    - Parse table output to extract API key and secret
    - Store key and secret in variables
    - _Requirements: 5.1, 5.2_

  - [x] 5.2 Add user interaction for TableFlow key creation

    - Check `--create-keys` flag for automatic creation
    - Prompt user with `confirm()` if flag not set
    - Skip TableFlow configuration if user declines
    - Handle dry-run mode with placeholder values
    - _Requirements: 5.3, 5.4, 5.5_

  - [x] 5.3 Add error handling for TableFlow key creation
    - Handle API key creation failures
    - Validate that key and secret were successfully parsed
    - Log success message with key identifier
    - Continue execution if key creation fails
    - _Requirements: 5.5_

- [x] 6. Update environment file generation

  - [x] 6.1 Modify `generate_env_file()` to include Flink configuration

    - Add Flink environment variables section (CC_FLINK_COMPUTE_POOL, CC_FLINK_REGION, CC_FLINK_CLOUD, CC_FLINK_API_KEY, CC_FLINK_API_SECRET)
    - Add conditional logic to only write Flink section if configuration is available
    - Maintain proper formatting and comments
    - _Requirements: 6.1, 6.2_

  - [x] 6.2 Modify `generate_env_file()` to include TableFlow configuration

    - Add TableFlow environment variables section (CC_TF_API_KEY, CC_TF_API_SECRET, CC_TF_CATALOG_URL, CC_ORG_ID)
    - Add conditional logic to only write TableFlow section if configuration is available
    - Maintain proper formatting and comments
    - _Requirements: 6.3, 6.4_

  - [x] 6.3 Add legacy format mappings for backward compatibility

    - Add CONFLUENT*FLINK*\* variable mappings
    - Add CONFLUENT*TABLEFLOW*\* variable mappings
    - Ensure mappings reference CC\_\* variables
    - _Requirements: 6.5_

  - [x] 6.4 Add file permissions for security
    - Set `.env` file permissions to 600 (read/write for owner only)
    - Add security warning comment in generated file
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 7. Integrate new functions into main workflow

  - [x] 7.1 Add Flink discovery call in `main()` function

    - Call `discover_flink_compute_pool()` after Schema Registry discovery
    - Check if `--skip-flink` flag is set before calling
    - Handle function return status
    - _Requirements: 1.1, 7.1_

  - [x] 7.2 Add Flink key creation call in `main()` function

    - Call `create_flink_api_key()` after Flink discovery
    - Only call if compute pool was discovered
    - Handle function return status
    - _Requirements: 2.1, 7.5_

  - [x] 7.3 Add TableFlow discovery call in `main()` function

    - Call `discover_tableflow()` after Flink key creation
    - Check if `--skip-tableflow` flag is set before calling
    - Handle function return status
    - _Requirements: 4.1, 7.2_

  - [x] 7.4 Add TableFlow key creation call in `main()` function
    - Call `create_tableflow_api_key()` after TableFlow discovery
    - Only call if TableFlow was discovered
    - Handle function return status
    - _Requirements: 5.1, 7.5_

- [x] 8. Update output and summary displays

  - [x] 8.1 Update `show_env_preview()` function

    - Add Flink compute pool information display
    - Add TableFlow catalog URL display
    - Use consistent formatting with existing resources
    - _Requirements: 8.1, 8.2_

  - [x] 8.2 Update success message and next steps
    - Add Flink validation commands to next steps
    - Add TableFlow validation commands to next steps
    - Maintain consistent emoji and color usage
    - _Requirements: 8.3, 8.4, 8.5_

- [x] 9. Add validation and testing

  - [x] 9.1 Test dry-run mode with all flags

    - Verify `--dry-run` works with Flink discovery
    - Verify `--dry-run` works with TableFlow discovery
    - Verify placeholder values are used correctly
    - _Requirements: 3.4_

  - [x] 9.2 Test skip flags

    - Verify `--skip-flink` skips Flink discovery and configuration
    - Verify `--skip-tableflow` skips TableFlow discovery and configuration
    - Verify both flags can be used together
    - _Requirements: 7.1, 7.2, 7.4_

  - [x] 9.3 Test error handling paths

    - Test behavior when Flink compute pools don't exist
    - Test behavior when TableFlow is not available
    - Test behavior when API key creation fails
    - Verify graceful degradation in all cases
    - _Requirements: 1.4, 4.4, 3.3_

  - [x] 9.4 Test complete workflow
    - Test with environment containing all resources
    - Test with environment missing Flink
    - Test with environment missing TableFlow
    - Verify generated `.env` file is correct in all cases
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 10. Update Makefile targets for validation

  - [x] 10.1 Verify existing Makefile targets work with new variables

    - Test `make list-flink` target
    - Test `make list-tableflow` target
    - Verify targets use correct environment variables
    - _Requirements: 8.4_

  - [x] 10.2 Update `make validate-all` target
    - Ensure Flink validation is included if configured
    - Ensure TableFlow validation is included if configured
    - Maintain backward compatibility
    - _Requirements: 8.4_
