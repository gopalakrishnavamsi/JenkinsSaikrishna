# DfS Contribution Guidelines

## Before submitting a PR
1. Verify you are pointing to the correct target branch.
2. Ensure Apex code is covered by unit tests.
2. Ensure all files you touch are properly formatted. Current style configurations are located in the [`style` directory](https://github.docusignhq.com/Integrations/Salesforce/tree/master/style).  
3. Run all unit tests against your dev org.
    - Also run all unit tests against a clean org via `ant test`. (RECOMMENDED)
4. Ensure commit(s) build successfully via CI integration.
    - If you break the build, you get the skull.
5. Fill out entire PR form with accurate information.
6. If security-related, be sure to include @john-heasman or a security team member as a code reviewer.

## Apex Style guide
As Apex is very similar to Java in syntax, we adhere to the [Google Java style guide](https://google.github.io/styleguide/javaguide.html).

Additionally, DfS Apex code must:
- Use **tabs** over **spaces** for indentation. This is considered best practice because every Apex class character counts towards Force.com limits.
- Use consistent capitalization even though Apex is (mostly) case-insensitive.
- Use proper spelling.
- Use consistent, concise, and clear type and variable naming. Do not prepend `DocuSign` or `DS` to type names unless it must be disambiguated from other types. Keep in mind that all types in the DfS managed package will include the namespace prefix `dfsle__`.

| Bad Naming | Good Naming |
| --- | ---- |
| `DocuSignListController` | `ListController` |
| `mySourceId` | `sourceId` |
| `theEnvelope` | `envelope` |
| `isSetFlag` | `isSet` |
| `templatte` | `template` |
| `SomeTYPe` | `SomeType` |
| `SomeProperty` | `someProperty` |
| `someConstant` | `SOME_CONSTANT` |

Eventually, linting will be introduced into our CI process and fail with any code that does not meet our style standards. 

## Standards and Best Practices

### Privacy and Security
- **NEVER** commit secret or sensitive information to Github.
- **NEVER** log sensitive information, e.g. passwords, tokens, PII, CPNI, PCI, etc.
- **NEVER** use un-encoded user input directly. Use [JSENCODE](https://developer.salesforce.com/page/Secure_Coding_Cross_Site_Scripting#Built_in_Auto_Encoding) for query string parameters in JavaScript.
- **NEVER** build URLs by concatenating strings based on user input. Use `RestAPI.sendRequest()` and create appropriate proxy methods. 
- **NEVER** serialize to JSON by concatenating strings. This is error-prone and a potential [attack vector](https://www.owasp.org/index.php/AJAX_Security_Cheat_Sheet#Avoid_building_XML_or_JSON_dynamically).
- **ALWAYS** authorize actions for appropriate role via the `Permissions` class. Be especially vigilant with `@RemoteAction`.

|Action|Requirement|Verification|
|------|----------|-----|
|All Admin|DocuSign administrator|`verifyIsDocuSignAdministrator()`|
|Create Envelope|DocuSign user|`verifyIsDocuSignUser()`|
|Edit and Send Envelope|Envelope owner|`verifyIsOwner()`|

- **ALWAYS** check CRUD and FLS with the `Permissions.verifyIs*` methods.    
- **ALWAYS** use appropriate randomness and entropy when generating secrets. E.g. use `UUID.randomUUID().toString()`.
- **AVOID** dynamic SOQL unless absolutely necessary.

### General
- Proper naming is important (and difficult!)
- Always leave the code in a better state than when you began.
- Favor conciseness and readability.
- Keep methods as small and as focused as possible.
- Avoid overly generic or catch-all classes and methods, e.g. `DocuSignUtils`.
- Treat all `public` classes as if they are `global`, i.e. assume they may be exposed to our customers and partners at some point.
 
### Coding 
- Adhere to [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle).
- Favor [immutability](https://en.wikipedia.org/wiki/Immutable_object). This makes the code easier to comprehend and mitigates entire classes of bugs.
- Avoid returning `null`, but check for it exhaustively.
- Avoid superfluous logging. This is expensive on the Force.com platform and we quickly run into size limits. It also reduces the readability of logs.
Once the feature is implemented and unit tested, log only exceptional cases using `LoggerService`.
- Avoid short-circuiting non-trivial functions by returning in the middle.
- Avoid side effects such as writing to the database or making a callout unless the function is clearly marked as such.
- Avoid `void` return types. Functions should return the result of some computation or action.
- Functions should do one thing and one thing only. If it is doing two things, it should be broken into two functions.
- Prefer [fluent interfaces](https://en.wikipedia.org/wiki/Fluent_interface).
- Only URL-decode or encode at the point where is returned to or read from the client. Bear in mind the Force.com platform will automatically do this conversion for you when reading or writing query string values.
- Do not repeat yourself ([DRY](https://en.wikipedia.org/wiki/Don't_repeat_yourself)). If the same logic exists in two places, it is a good time to refactor. 
- Do not overload or overuse strings for various return types or statuses. Checking the string for specific values is error-prone and brittle.
- Use specific types where appropriate: `Id`, `UUID`, `URL`, etc. This gives us free validation.
- Do not reinvent the wheel. Check to see if someone has already implemented some or all of your code and reuse.
- Do not swallow exceptions or otherwise silently fail. No empty `catch` blocks.
- Only catch exceptions if you will handle them, otherwise let them bubble up the stack.
- Code that relies on non-default features such as `Quote` or `FeedItem` must use generic `SObjects` in place of the reified types. This code will fail on organizations that do not have these enabled.
- Use `Salesforce` class methods to determine org feature support.
- Do not directly return API-specific types from `RestAPI`. This causes external representations to be strongly coupled with our internal ones and leads to anti-patterns such as using `String` in place of more specific types such as `Boolean`, `Integer`, or `Decimal`.

### Testing
- Unit test all the things.
- Keep unit tests small and focused.
- Cover 100% of new code with unit tests.
- Do not mix test and production code, e.g. `if (Test.isRunningTest()) { return testData; } else { return realData; }`.
- Validate all output in unit tests. Use copious test assertions. Assert that you are assertively asserting.
- Do not make assumptions about available org data or namespace. Assume clean state for every test.
- Do not use `@IsTest(SeeAllData = true)`. Your test does not need to see it and will almost certainly break on other orgs. 
- If your test performs CRUD operations or requires certain permissions to succeed, create required users via `TestUtils` methods and execute tests in a `System.runAs(user) {}` context.
- Test both authorized and unauthorized scenarios.
- Wrap actual test part of the code with `Test.startTest()` and `Test.stopTest()`. This resets context and governor limits.
- `Test.stopTest()` also causes asynchronous code (e.g. `@future` methods) to immediately complete, thus making the result of the asynchronous code assertable.
- Unless you need a very specific callout response, make use of standard test mocks such as `DocuSignAPITest.SuccessMock`.
- The `TestUtils` class is your friend. It has methods to easily and safely create all sorts of test data, users with varying access, 
etc.
