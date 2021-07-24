# Automate First generation Package creation using sfdx cli
Typical steps we can automate when developing Salesforce managed package (First generation Packaging)
1. CI - deploy master to packaging org.
2. check if package.xml has any change.
2.1. if it has no change in package.xml then goto Step 3
2.2. if it does then include components to managed package and approve the CI step.
2.3 After approval goto Step 3
3. get latest packages and get the latest version
3.1. increment that by 1 and create a beta package.
3.2. create scratch org, install this beta package there and run smoke test.
3.3. notify admin with Smoke test result.
4. If smoke test pass, go ahead and create a managed package and run smoke test again.

## Create next version of managed package with script
* sample cmd with required arguments
```sh generate-package.sh -pid <packagid> -u <usernameofpackgingorg>```
* example
```sh generate-package.sh -pid 033blahahaha -u packagingorg@example.com```
