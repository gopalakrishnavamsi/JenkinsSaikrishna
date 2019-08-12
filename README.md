# DocuSign for Salesforce Essentials

This is the new DocuSign for Salesforce base package. This is a lighter version of DFS that is installable on Salesforce Essentials organizations. This package also contains the Apex Toolkit.

[API Documentation and Code Examples](https://developers.docusign.com/salesforce/)

## Development Notes
Salesforce DX is used to build, test, and deploy this project.
1. [Install and configure Salesforce DX](./doc/sfdx.md).
2. Create a Developer scratch org or an Enterprise scratch org depending upon your use case.
- Developer scratch org: `sfdx force:org:create -f ./etc/developerScratch.json -s -a dfsle-scratch-org`. This org will allow creation of only 2 salesforce standard users associated with the scratch org.
- Enterprise scratch org: `sfdx force:org:create -f ./etc/enterpriseScratch -s -a dfsle-scratch-org`. This org will allow creation 10 salesforce standard users associated with the scratch org.
- Scratch orgs persist for 7 days by default. Use the `-d` parameter to set a custom expiration time. Customize aliases associated with scratch orgs in the command by changing `dfsle-scratch-org` to the desired value. 
3. Push the source to your scratch org: `sfdx force:source:push`.
4. Run post-install scripts in your scratch org: `sfdx force:apex:execute -f ./etc/postinstall.apex -u dfsle-scratch-org`.
5. To complete OAuth flows, you must create a password for your scratch org user: `sfdx force:user:password:generate -u dfsle-scratch-org`. Note the password returned by this command. If necessary, you can view the generated password later via `sfdx force:user:display -u dfsle-scratch-org`.

Once you have completed the initial scratch org setup, you can sync any local changes with that org using the `sfdx force:source:push`.

### Update: Shortcut Commands
1. In addition to using SFDX commands directly you can run "npm init" (if it’s your first time running npm scripts on this package) then run "npm setup". The npm setup command will run all necessary commands for generating a sandbox/ configuration sequentially and prompt for responses as needed.

## Installing and running ESLint (pre-requisites : have npm installed)
To install ESLint in mac run - 'npm install'
To run linting run - 'npm run lint'.

## Testing Notes
- Run unit tests with coverage: `sfdx force:apex:test:run -c -r human -w 5`. This will wait 5 minutes for the test run to complete. You can also execute this command asynchronously by omitting `-w #`.
- Default test scratch orgs should use the configuration located at `etc/test.json`.
- You will need a password for your scratch org user to complete setup OAuth flows. See *Development Notes* for details.

## Packaging Notes
Until Salesforce 2nd Generation packages (2GP) is GA, we will continue manually uploading new package versions on our packaging org.
1. Connect the packaging org: `sfdx force:auth:web:login -a dfsle-packaging-org`. This is a one-time step. You can use whatever alias you desire.
1. Deploy the code: `sfdx force:source:deploy -u dfsle-packaging-org -p ./pkg -w 15`. This will wait 15 minutes for the deployment to complete. You can also execute this command asynchronously by omitting `-w #`.

When uploading the managed package, you must set the post-install splash page. From the upload screen:

1. Under "Post Install Instructions", select "Visualforce Page".
1. Under "Post Install Page", select "DocuSign Setup Splash Page [dfsle__SetupSplash]"
1. Click "Upload".

![Package Upload](./img/package_upload.png)

## DX Notes
To clean up any leftover orgs/configs in your local mac
- Go to .sfdx folder in your home directory and clean up the .json files associated with the particular org causing the issue. No CLI command with DX yet to do the cleanup.


