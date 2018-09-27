# DocuSign for Salesforce - Core

This is the new DocuSign for Salesforce base package. This is a lighter version of DFS that is installable on Salesforce Essentials organizations.

[API Documentation and Code Examples](https://developers.docusign.com/salesforce/)

## Packaging Notes

When creating a managed package, you must set the post-install splash page. From the upload screen:

1. Under "Post Install Instructions", select "Visualforce Page".
1. Under "Post Install Page", select "DocuSign Setup Splash Page [dfsle__SetupSplash]"
1. Click "Upload".

![Package Upload](./img/package_upload.png)
