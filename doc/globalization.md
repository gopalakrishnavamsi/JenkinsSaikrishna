## Salesforce Product Globalization

Our products officially support 12 languages and many different locales. This is often challenging to support, but we have a world-class localization team and solid guidelines to assist.

Before you begin, review the localization team's general guidelines: [DocuSign Localizability Checklist](https://docs.google.com/document/d/1epVseiCPBUNfbqPSZEmwcNZoSam0fbMNVrkGkASsbdo/edit?ts=5bed9cfa#heading=h.gjdgxs). This document is focused on Salesforce-specific globalization considerations.

### Custom Labels

**Prime directive: No user-visible string may be hardcoded.**

Every string that will be visible to the user must be a reference to a custom label in `labels/CustomLabels.labels-meta.xml` and have a default translation in `translations/en_US.translation-meta.xml`. Any code with hardcoded user-visible strings, English or otherwise, will immediately fail code review. Be vigilant about this both as a developer and as a code reviewer. Verify labels are used for the following:
- HTML labels and text
- Exception messages
- Visualforce page titles
- Image alt-text
- en-US URLs
- Customer email templates

Be on the lookout for string concatenation (e.g. `Label.A + ': ' + Label.B`) in any Apex, Visualforce, or Lightning component. This prevents proper translations to other languages. Instead create format labels and use a string formatting function. For example, a label `MyLabel` defined as "{0} loves string formatting!" can be formatted in Apex:
   ```apex
   String s = String.format(MyLabel, new List<Object> { 'Abby Admin' });
   // s == 'Abby Admin loves string formatting!'
   ```  
Or in Aura markup using the `format` expression function:
   ```xhtml
   <lightning:formattedRichText value="{!format($Label.c.MyLabel, 'Sam Sales')}"/>
   <!-- Sam Sales loves string formatting! -->
   ```
Or in JavaScript using our `stringUtils.format` function:
   ```javascript
   var s = stringUtils.format($A.get('$Label.c.MyLabel'), 'Dave Developer');
   // s == Dave Developer loves string formatting!
   ```

Do not depend on label translations in your business logic. This is an unfortunate source of bugs. For example, the following code will fail for non-English users:
```Apex
String errorMessage = System.Label.MyErrorMessage;

/* snip */

if (errorMessage.startsWith('Failed to connect')) {
  // this will only execute for English
} else {
  // do something else, always executed for non-English languages
}
```
Use invariant status codes instead. Avoiding ["stringly-typed"](http://wiki.c2.com/?StringlyTyped) data is best practice regardless.

This is also true for picklists and enumerations. Typically these are mapped to custom labels for display, but we must not rely on the labels for any business logic and ensure that the language-invariant form is persisted to any database.

### Object Translations

In Salesforce, just about *everything* is localizable. Each custom application, object, or public settings or metadata must have accompanying en-US `objectTranslations`. Protected custom settings or metadata do not need to be translated as those are only visible to us as the app developers.

### Date, Time, and Currency 

Do not format dates, times, or currencies in Apex code. Use the following instead:
- [Lightning Aura Markup: `<lightning:formatted*>` or `<ui:output*>`](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/components_l10n.htm)
- [Lightning JavaScript: `$A.localizationService`](https://login.salesforce.com/auradocs/reference.app#reference?topic=api:AuraLocalizationService)
- [Visualforce: `<apex:outputText>`](https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/pages_compref_outputText.htm)

### Localization Process

Every major or minor release must be translated prior to creating the final build. Our localization team is awesome, but they need time to complete the 11 translations for each release. The more labels we add, the longer this process can take. A good rule of thumb is to allow at least 2 weeks to complete translations.

The process to submit files for localization is straightforward:
1. Ensure all en-US translations are final. We cannot keep adding new labels during the translation process.
1. Each en-US translation file must have Smartling directive at the top. This tells Smartling (semi-automated translation tool) where to find labels to translate. All possible paths must be specified in order to translate all the labels. For example:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!-- smartling.translate_paths = Translations/customApplications/label, Translations/customLabels/label, Translations/customPageWebLinks/label, Translations/customTabs/label -->
   <Translations xmlns="http://soap.sforce.com/2006/04/metadata">
   </Translations>
   ```
1. Commit the en-US translations to the master branch of the globalization repo. 
    - For DFS: https://github.docusignhq.com/globalization/salesforce-language
    - For DAL: https://github.docusignhq.com/globalization/unified-app-language
1. Give the localization team a heads-up in their Slack channel: [#localization](https://docusign.slack.com/archives/CJFRTE2BF).
1. Wait a few days and pull the translations from the repo. Ping the [#localization](https://docusign.slack.com/archives/CJFRTE2BF) Slack channel with questions, but don't bombard them with status requests. Remember, it takes time to properly translate our labels.
1. Merge into the Salesforce package repo. Some of the files may need renaming.

If you run into any issues with the globalization repo, contact [@colin.sprague](https://docusign.slack.com/archives/DL4UWL0LF).
