# Envelope Multi-Send with the Apex Toolkit
This example shows you how to send multiple envelopes in a single transaction using the Apex Toolkit. For example, HR may send out a batch of customized offer letters at one time. 

Multi-Send is distinct from [Bulk Sending](../salesforce-bulk-send) in that each envelope in this scenario can be unique without the recipient limits imposed by Bulk Sending. If you are sending the same document for signature to a list of recipients, Bulk Sending the most efficient option. Carefully consider whether Bulk Sending is more appropriate for your use case. 

This action may be wrapped in an [@InvocableMethod](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm), enabling sending a batch of envelopes via [Lightning Process Builder](https://help.salesforce.com/articleView?id=process_overview.htm&type=5).

There are some limits to be aware of when triggering Envelope Multi-Send:
* You are limited to 99 envelopes in a single transaction. This corresponds to Salesforce callout limits per transaction with one callout reserved for requesting a DocuSign access token.
* You may send up to 1000 envelopes in an hour via the Apex Toolkit. See [API Resource Limits](/esign-rest-api/v2/guides/resource-limits) for more details.
* You cannot create draft envelopes using this method. Any envelope that is not fully ready to be sent will prevent all other envelopes in the same transaction from being sent.

## Before You Begin
1. Install the [DocuSign Apps Launcher](https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FK9gtUAD) managed package.
1. Navigate to the DocuSign Setup tab and complete the login step.
1. Use the code provided in your application's Apex classes as a basis for your implementation of Envelope Multi-Send.

## 1. Prepare the envelopes
Build up to 99 envelopes using the Apex Toolkit. You can merge data from Salesforce into your envelopes and each envelope may be unique. In the example below, we will send offer letters to Contacts with the offer "Prepared" stage. For example purposes, we assume some custom fields exist on the Contact object and that each Contact in this stage has an offer letter linked to their record.

Unlike with `dfsle.EnvelopeService.sendEnvelope`, you will not have an opportunity to tag the envelope draft before sending. You should consider using [AutoPlace Fields](https://support.docusign.com/en/guides/dfs-admin-guide-automatic-anchor-text-and-tags) in your documents or [DocuSign Templates](https://support.docusign.com/guides/ndse-user-guide-working-with-templates) when sending with this method.

The following code demonstrates how to build a list of envelopes to send. 

```Apex
// Get up to 99 contacts in the "Prepared" offer stage.
List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE OfferStage__c = 'Prepared' LIMIT 99];

// Build a list of offer envelopes to send.
List<dfsle.Envelope> envelopes = new List<dfsle.Envelope>();
for (Contact c : contacts) {
    // Get an empty envelope with org defaults
    envelopes.add(dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(c.Id))
        // Customize the email subject and message.
        .withEmail('Offer Letter for ' + c.Name, c.Name + ', please review and sign the enclosed offer letter.')
        // Add linked offer letter to envelope
        .withDocuments(dfsle.DocumentService.getLinkedDocuments(
            ContentVersion.getSObjectType(),
            new Set<Id> { c.Id },
            true))
        // Add the contact as a recipient
        .withRecipients(dfsle.RecipientService.getRecipients(
            Contact.getSObjectType(), 
            new Set<Id> { c.Id })));
}
````

## 2. Send the envelopes
Now that we have built a list of offer letters to send, we can send all of them in a single batch using the [`dfsle.EnvelopeService.sendEnvelopes`](/salesforce/apex-toolkit-reference/envelopeservice.html) method. Invoking this method triggers a number of callouts to the DocuSign API equal to the size of the input envelope list plus one to request an access token. Unlike `dfsle.EnvelopeService.sendEnvelope`, this method will not create any associated envelope or status records in Salesforce.

This method may be partially successful. If any error is returned by the DocuSign API, the `dfsle.Envelope.error` property will contain the error details.

If you exceed your DocuSign API hourly limit, the `dfsle.Envelope.error.code` will be `dfsle.APIErrorCode.HOURLY_API_LIMIT_EXCEEDED`. You must wait until the hourly count is reset to continue sending envelopes. Bear in mind that most other DocuSign API callouts count against your hourly limit. Refer to the [resource limits guide](/esign-rest-api/guides/resource-limits) for more details on API limits.

The following code demonstrates how to send a list of envelopes and verify the results.

```Apex
// Send the envelopes and determine which envelopes were sent successfully. Filter out unsuccessfully sent envelopes.
List<Contact> contactsToUpdate = new List<Contact>();
List<dfsle.Envelope> sentEnvelopes = new List<dfsle.Envelope>();
for (dfsle.Envelope envelope : dfsle.EnvelopeService.sendEnvelopes(envelopes)) {
    if (envelope.error == null) {
        // Envelope sent successfully.
        sentEnvelopes.add(envelope);
        contactsToUpdate.add(new Contact(
            Id = envelope.source.id,
            OfferStage__c = 'Out for Signature'));
    } else {
        // Handle send error.
        System.debug('Envelope error: ' + envelope.error);
    }      
}

// Update the Contact offer stage to "Out for Signature".
update contactsToUpdate;
```

## 3. Save the sent envelopes in Salesforce
Once the envelopes are sent, you may want to create the associated envelope and status records in Salesforce. We will use the `dfsle.EnvelopeService.saveSentEnvelopes` method to create these records. This step is required if you want to track the envelope status within Salesforce.

Only successfully-sent envelopes may be updated with `dfsle.EnvelopeService.saveSentEnvelopes`. If any invalid envelopes are passed into this method, a `dfsle.DocuSignException` is thrown and no DML update is performed.

The following code demonstrates how to save the sent envelopes in Salesforce.

```Apex
List<dfsle.Envelope> savedEnvelopes = dfsle.EnvelopeService.saveSentEnvelopes(sentEnvelopes);
```

## 4. Get envelope status 
DocuSign administrators can track the status of DocuSign envelopes after sending them to recipients by using the Apex Toolkit getStatus method. This method returns the current status of the envelope (Created, Deleted, Sent, Delivered, Signed, Completed, or Declined), the time and date of the most recent action on the envelope, and other information, as a list of Envelope.Status objects. This method is passed a set of Salesforce source records that are associated with envelopes and a integer specifying the maximum number of records that will be returned.

Getting envelope status is useful for ensuring that the envelope operations you've already performed, such as sending, confirming delivery or signing, and completion, have been executed successfully and to detect new status changes for an envelope. You must be the sender of the envelopes to call this method.

The following code demonstrates how to get the status of the sent envelopes.

```Apex
// Build a list of Contact IDs to query.
Set<Id> contactIds = new Set<Id>();
for (dfsle.Envelope envelope : savedEnvelopes) {
    contactIds.add(envelope.source.id);
}

// Retrieve the most recent envelope statuses from the Salesforce source objects.
// The status results are sorted oldest to newest.
List<dfsle.Envelope.Status> statuses = dfsle.StatusService.getStatus(
    contactIds, // Envelope source object IDs. 
    99); // Maximum number of records to return.

// Display or take action on the returned statuses.
```
