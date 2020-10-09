# Automated Letter Sending

This section is regarding the automation of how we send letters to tenants. The automation process is broken down into various customisable sections which make up this feature.

The `automate_sending_letters` orchestrator use case is where the code lives `lib/use_cases/automate_sending_letters.rb`

You have the flexibility to change the automation settings within AWS, you can:

- Turn on and off automation - **AWS ENV VARIABLE** `CAN_AUTOMATE_LETTERS`
- Turn on and off automation for income collection Letter 1 - **AWS ENV VARIABLE** `AUTOMATE_INCOME_COLLECTION_LETTER_ONE`
- Turn on and off automation for income collection Letter 2 - **AWS ENV VARIABLE** `AUTOMATE_INCOME_COLLECTION_LETTER_TWO`
- Add or remove patches which can allow for automation - **AWS ENV VARIABLE** `PATCH_CODES_FOR_LETTER_AUTOMATION`

The AWS variables are the same across staging and production.

In order to change any of these variables you will need to:

1. Login to AWS
2. Go to **ECS**
3. Locate and select **Task Definitions** on the left-hand sidebar
4. Search for `task-income-` in the 'Filter in this page' field above the table.
5. Select `income-api-production` or `income-api-staging`.
6. Click on the Task definition you'd like to base your new one off.
This will usually be the most recent, i.e. the one with the greatest tag number.
7. Click **Create new revision**
8. Locate 'Container definitions' and select the `income-api-production-worker` container.
9. Locate the 'ENVIRONMENT' section of the slide-out.
10. Add/Modify the relevant Environment Variables.
11. Click **Update** at the bottom of the slide-out when you have finished making changes/additions.
12. Click **Create** at the bottom of the 'Create new revision' page.
13. Verify that the Environment Variables have been inputted correctly, to check this click on the **JSON** tab of the newly created task definition
14. Check that all the Environment Variables are correct, look for issues such as trailing whitespace e.g. `AUTOMATE_INCOME_COLLECTION_LETTER_ONE\t` (i.e. trailing \<TAB\> character) or special characters.
15. If you find any issues with any of the Environment Variables, follow the above steps to create a new Task Definition with the correct ones.
16. There is now a new Task Definition, but it has not been applied yet.
**You must ENSURE YOU [REDEPLOY](../development/Releasing.md#manual-redeployment) to have your changes applied**

**IMPORTANT: IF YOU UPDATE THE TASK DEFINITION BY CHANGING ANY OF THE ABOVE YOU NEED TO REDEPLOY IN ORDER FOR THE NEW INSTANCE TO USE THE NEW TASK DEFINITION**
