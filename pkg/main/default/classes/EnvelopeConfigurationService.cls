public with sharing class EnvelopeConfigurationService {

	@TestVisible
	private static final EnvelopeConfigurationService.Database DB = new EnvelopeConfigurationService.Database();
	private static final SObjectType CONTENT_DOCUMENT_TYPE = ContentDocument.getSObjectType();

	private class Database {

		@TestVisible
		private EnvelopeConfiguration__c convert(
			final EnvelopeConfiguration ec,
			final Boolean forUpdate) {

			if (ec == null) return null;

			EnvelopeConfiguration__c result = new EnvelopeConfiguration__c(
				Id = ec.id,
				Name = ec.name,
				DocuSignId__c = String.valueOf(ec.docuSignId),
				CustomFields__c = Collection.isEmpty(ec.customFields) ? null : JSON.serialize(ec.customFields),
				Notifications__c = ec.notifications == null ? null : JSON.serialize(ec.notifications),
				EmailSubject__c = ec.emailSubject,
				EmailMessage__c = ec.emailMessage,
				MergeFields__c = Collection.isEmpty(ec.mergeFields) ? null : JSON.serialize(ec.mergeFields),
				SenderPermissions__c = ec.senderPermissions == null ? null : JSON.serialize(ec.senderPermissions),
				Options__c = ec.options == null ? null : JSON.serialize(ec.options),
				IsDraft__c = ec.isDraft == true);
			if (!forUpdate) result.SourceObject__c = ec.sourceObject;
			return result;
		}

		@TestVisible
		private EnvelopeConfigurationDocument__c convert(
			final Id envelopeConfigurationId,
			final Document document) {

			if (document == null) return null;

			String filter = null;
			if (document instanceof EnvelopeConfiguration.SourceFiles) {
				EnvelopeConfiguration.SourceFiles sfs = (EnvelopeConfiguration.SourceFiles)document;
				if (sfs.filter != null) filter = JSON.serialize(sfs.filter);
			}

			return new EnvelopeConfigurationDocument__c(
				Id = document.id,
				EnvelopeConfiguration__c = envelopeConfigurationId,
				SourceId__c = document.sourceId,
				Filter__c = filter,
				Sequence__c = document.sequence,
				Name__c = document.name,
				Extension__c = document.extension,
				ReadOnly__c = document.readOnly == true,
				Required__c = document.required == true,
				Type__c = document.type);
		}

		@TestVisible
		private List<EnvelopeConfigurationDocument__c> convert(
			final Id envelopeConfigurationId,
			final List<Document> documents) {

			List<EnvelopeConfigurationDocument__c> result = new List<EnvelopeConfigurationDocument__c>();
			if (documents != null) {
				Integer sequence = 0;
				for (Document d : documents) {
					if (d != null) result.add(convert(envelopeConfigurationId, d.withSequence(++sequence)));
				}
			}
			return result;
		}

		@TestVisible
		private EnvelopeConfigurationRecipient__c convert(
			final Id envelopeConfigurationId,
			final Recipient recipient) {

			if (recipient == null) return null;

			String relationship = null, filter = null;
			String roles = recipient.role == null ? null : recipient.role.name;
			Boolean incrementRoutingOrder = true;
			if (recipient instanceof EnvelopeConfiguration.RelatedRecipients) {
				EnvelopeConfiguration.RelatedRecipients rrs = (EnvelopeConfiguration.RelatedRecipients)recipient;
				if (rrs.relationship != null) relationship = JSON.serialize(rrs.relationship);
				if (rrs.filter != null) filter = JSON.serialize(rrs.filter);
				incrementRoutingOrder = rrs.incrementRoutingOrder == true;
				if (rrs.roles != null) roles = String.join(rrs.roles, ';');
			} else if (recipient instanceof EnvelopeConfiguration.LookupRecipient) {
				EnvelopeConfiguration.LookupRecipient lr = (EnvelopeConfiguration.LookupRecipient)recipient;
				if (lr.relationship != null) relationship = JSON.serialize(lr.relationship);
			}

			return new EnvelopeConfigurationRecipient__c(
				Id = recipient.id,
				EnvelopeConfiguration__c = envelopeConfigurationId,
				Relationship__c = relationship,
				Filter__c = filter,
				IncrementRoutingOrder__c = incrementRoutingOrder,
				Type__c = recipient.type,
				Sequence__c = recipient.sequence,
				RoutingOrder__c = recipient.routingOrder,
				Roles__c = roles,
				Name__c = recipient.name,
				Email__c = recipient.email,
				SigningGroupId__c = recipient.signingGroup == null ? null : recipient.signingGroup.id,
				SigningGroupName__c = recipient.signingGroup == null ? null : recipient.signingGroup.name,
				AccessCode__c = recipient.authentication == null ? null : recipient.authentication.accessCode,
				IdCheckRequired__c = recipient.authentication != null
					&& recipient.authentication.idCheckRequired == true,
				SmsPhoneNumber__c = recipient.authentication == null ? null :
					(String)Collection.head(recipient.authentication.smsPhoneNumbers),
				Note__c = recipient.note,
				Language__c = recipient.emailSettings == null ? null : recipient.emailSettings.language,
				EmailSubject__c = recipient.emailSettings == null ? null : recipient.emailSettings.subject,
				EmailMessage__c = recipient.emailSettings == null ? null : recipient.emailSettings.message,
				HostName__c = recipient.hostName,
				HostEmail__c = recipient.hostEmail,
				SignNow__c = recipient.signNow == true,
				SourceId__c = recipient.getSourceId(),
				ReadOnly__c = recipient.readOnly == true,
				Required__c = recipient.required == true);
		}

		@TestVisible
		private List<EnvelopeConfigurationRecipient__c> convert(
			final Id envelopeConfigurationId,
			final List<Recipient> recipients) {

			List<EnvelopeConfigurationRecipient__c> result = new List<EnvelopeConfigurationRecipient__c>();
			if (recipients != null) {
				Integer sequence = 0;
				for (Recipient r : recipients) {
					if (r != null) result.add(convert(envelopeConfigurationId, r.withSequence(++sequence)));
				}
			}
			return result;
		}

		@TestVisible
		private Document convert(final EnvelopeConfigurationDocument__c d) {
			if (d == null) return null;

			if (d.Type__c == EnvelopeConfiguration.DOCUMENT_TYPE_SOURCE_FILES) {
				Query.Filter filter = null;
				if (String.isNotBlank(d.Filter__c)) {
					filter = (Query.Filter)JSON.deserialize(d.Filter__c, Query.Filter.class);
				}
				return new EnvelopeConfiguration.SourceFiles(
					d.Id,
					filter,
					Integer.valueOf(d.Sequence__c),
					d.ReadOnly__c == true,
					d.Required__c == true);
			} else { // linked template document
				return new EnvelopeConfiguration.TemplateDocument(
					d.Id,
					d.SourceId__c,
					Integer.valueOf(d.Sequence__c),
					d.Name__c,
					d.Extension__c,
					d.ReadOnly__c == true,
					d.Required__c == true);
			}
		}

		@TestVisible
		private List<Document> convert(final List<EnvelopeConfigurationDocument__c> documents) {
			List<Document> result = new List<Document>();
			if (documents != null) {
				for (EnvelopeConfigurationDocument__c d : documents) {
					if (d != null) result.add(convert(d));
				}
			}
			return result;
		}

		@TestVisible
		private Recipient convert(final EnvelopeConfigurationRecipient__c r) {
			if (r == null) return null;

			Query.Relationship relationship = null;
			if (String.isNotBlank(r.Relationship__c)) {
				relationship = (Query.Relationship)JSON.deserialize(
					r.Relationship__c,
					Query.Relationship.class);
				if (relationship.isLookup) {
					return new EnvelopeConfiguration.LookupRecipient(
						r.Id,
						relationship,
						r.Type__c,
						Integer.valueOf(r.Sequence__c),
						Integer.valueOf(r.RoutingOrder__c),
						r.Roles__c,
						r.Name__c,
						r.Email__c,
						r.SigningGroupId__c != null || String.isNotBlank(r.SigningGroupName__c)
							? new SigningGroup(Integer.valueOf(r.SigningGroupId__c), r.SigningGroupName__c) : null,
						r.SmsPhoneNumber__c,
						String.isBlank(r.AccessCode__c)
							&& r.IdCheckRequired__c != true ? null : new Recipient.Authentication(
							r.AccessCode__c,
							r.IdCheckRequired__c == true,
							r.IdCheckRequired__c == true && String.isNotBlank(r.SmsPhoneNumber__c)
								? new List<String> { r.SmsPhoneNumber__c } : null),
						r.Note__c,
						String.isBlank(r.Language__c)
							&& String.isBlank(r.EmailSubject__c)
							&& String.isBlank(r.EmailMessage__c) ? null : new Recipient.EmailSettings(
							r.Language__c,
							Localization.getLabel(r.Language__c),
							r.EmailSubject__c,
							r.EmailMessage__c),
						r.HostName__c,
						r.HostEmail__c,
						r.SignNow__c == true,
						null,
						r.ReadOnly__c == true,
						r.Required__c == true);
				} else {
					Query.Filter filter = null;
					if (String.isNotBlank(r.Filter__c)) {
						filter = (Query.Filter)JSON.deserialize(r.Filter__c, Query.Filter.class);
					}
					return new EnvelopeConfiguration.RelatedRecipients(
						r.Id,
						relationship,
						filter,
						r.IncrementRoutingOrder__c == true,
						r.Type__c,
						Integer.valueOf(r.Sequence__c),
						Integer.valueOf(r.RoutingOrder__c),
						String.isBlank(r.Roles__c) ? new List<String>() : r.Roles__c.split(';'),
						r.Name__c,
						r.Email__c,
						r.SigningGroupId__c != null || String.isNotBlank(r.SigningGroupName__c)
							? new SigningGroup(Integer.valueOf(r.SigningGroupId__c), r.SigningGroupName__c) : null,
						r.SmsPhoneNumber__c,
						String.isBlank(r.AccessCode__c)
							&& r.IdCheckRequired__c != true ? null : new Recipient.Authentication(
							r.AccessCode__c,
							r.IdCheckRequired__c == true,
							r.IdCheckRequired__c == true && String.isNotBlank(r.SmsPhoneNumber__c)
								? new List<String> { r.SmsPhoneNumber__c } : null),
						r.Note__c,
						String.isBlank(r.Language__c)
							&& String.isBlank(r.EmailSubject__c)
							&& String.isBlank(r.EmailMessage__c) ? null : new Recipient.EmailSettings(
							r.Language__c,
							Localization.getLabel(r.Language__c),
							r.EmailSubject__c,
							r.EmailMessage__c),
						r.HostName__c,
						r.HostEmail__c,
						r.SignNow__c == true,
						null,
						r.ReadOnly__c == true,
						r.Required__c == true);
				}
			} else {
				return new Recipient(
					r.Id,
					r.Type__c,
					Integer.valueOf(r.Sequence__c),
					Integer.valueOf(r.RoutingOrder__c),
					String.isBlank(r.Roles__c) ? null : new Recipient.Role(r.Roles__c),
					r.Name__c,
					r.Email__c,
					r.SigningGroupId__c != null || String.isNotBlank(r.SigningGroupName__c)
						? new SigningGroup(Integer.valueOf(r.SigningGroupId__c), r.SigningGroupName__c) : null,
					r.SmsPhoneNumber__c,
					String.isBlank(r.AccessCode__c)
						&& r.IdCheckRequired__c != true ? null : new Recipient.Authentication(
						r.AccessCode__c,
						r.IdCheckRequired__c == true,
						r.IdCheckRequired__c == true && String.isNotBlank(r.SmsPhoneNumber__c)
							? new List<String> { r.SmsPhoneNumber__c } : null),
					r.Note__c,
					String.isBlank(r.Language__c)
						&& String.isBlank(r.EmailSubject__c)
						&& String.isBlank(r.EmailMessage__c) ? null : new Recipient.EmailSettings(
						r.Language__c,
						Localization.getLabel(r.Language__c),
						r.EmailSubject__c,
						r.EmailMessage__c),
					r.HostName__c,
					r.HostEmail__c,
					r.SignNow__c == true,
					String.isBlank(r.SourceId__c) ? null : new Entity(r.SourceId__c),
					r.ReadOnly__c == true,
					r.Required__c == true);
			}
		}

		@TestVisible
		private List<Recipient> convert(final List<EnvelopeConfigurationRecipient__c> recipients) {
			List<Recipient> result = new List<Recipient>();
			if (recipients != null) {
				for (EnvelopeConfigurationRecipient__c r : recipients) {
					if (r != null) result.add(convert(r));
				}
			}
			return result;
		}

		@TestVisible
		private EnvelopeConfiguration convert(final EnvelopeConfiguration__c ec) {
			if (ec == null) return null;

			return new EnvelopeConfiguration(
				ec.Id,
				ec.Name,
				ec.SourceObject__c,
				UUID.tryParse(ec.DocuSignId__c),
				convert(ec.Documents__r),
				convert(ec.Recipients__r),
				String.isBlank(ec.CustomFields__c) ? null :
					(List<CustomField>)JSON.deserialize(ec.CustomFields__c, List<CustomField>.class),
				String.isBlank(ec.Notifications__c) ? null :
					(Notifications)JSON.deserialize(ec.Notifications__c, Notifications.class),
				ec.EmailSubject__c,
				ec.EmailMessage__c,
				String.isBlank(ec.MergeFields__c) ? null :
					(List<Tab>)JSON.deserialize(ec.MergeFields__c, List<Tab>.class),
				String.isBlank(ec.SenderPermissions__c) ? null :
					(Envelope.Permissions)JSON.deserialize(ec.SenderPermissions__c, Envelope.Permissions.class),
				String.isBlank(ec.Options__c) ? null :
					(Envelope.Options)JSON.deserialize(ec.Options__c, Envelope.Options.class),
				ec.IsDraft__c == true);
		}

		public EnvelopeConfiguration insertEnvelopeConfiguration(final EnvelopeConfiguration envelopeConfiguration) {
			Permissions.verifyIsCreateable(EnvelopeConfiguration__c.getSObjectType(), new List<String> {
				'Name',
				Application.namespacePrefix + 'CustomFields__c',
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'IsDraft__c',
				Application.namespacePrefix + 'MergeFields__c',
				Application.namespacePrefix + 'Notifications__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'Options__c',
				Application.namespacePrefix + 'SourceObject__c'
			});
			Permissions.verifyIsCreateable(EnvelopeConfigurationDocument__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'Filter__c',
				Application.namespacePrefix + 'Name__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});
			Permissions.verifyIsCreateable(EnvelopeConfigurationRecipient__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'Filter__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'IncrementRoutingOrder__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Name__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Relationship__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Roles__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			if (envelopeConfiguration == null) return null;

			EnvelopeConfiguration__c ec = convert(envelopeConfiguration, false);
			insert ec;

			List<EnvelopeConfigurationDocument__c> documents = null;
			if (Collection.isNotEmpty(envelopeConfiguration.documents)) {
				documents = convert(ec.Id, envelopeConfiguration.documents);
				insert documents;
			}

			List<EnvelopeConfigurationRecipient__c> recipients = null;
			if (Collection.isNotEmpty(envelopeConfiguration.recipients)) {
				recipients = convert(ec.Id, envelopeConfiguration.recipients);
				insert recipients;
			}

			return envelopeConfiguration
				.withId(ec.Id)
				.withDocuments(convert(documents))
				.withRecipients(convert(recipients));
		}

		public EnvelopeConfiguration queryEnvelopeConfiguration(final Id envelopeConfigurationId) {
			if (String.isBlank(envelopeConfigurationId)) return null;

			return convert((EnvelopeConfiguration__c)Collection.head([
				SELECT Id,
					Name,
					SourceObject__c,
					DocuSignId__c,
					CustomFields__c,
					Notifications__c,
					EmailSubject__c,
					EmailMessage__c,
					MergeFields__c,
					SenderPermissions__c,
					Options__c,
					IsDraft__c, (
					SELECT Id,
						Type__c,
						SourceId__c,
						Filter__c,
						Sequence__c,
						Name__c,
						Extension__c,
						ReadOnly__c,
						Required__c
					FROM Documents__r
					ORDER BY Sequence__c ASC NULLS LAST
				), (
					SELECT Id,
						Relationship__c,
						Filter__c,
						IncrementRoutingOrder__c,
						Type__c,
						Sequence__c,
						RoutingOrder__c,
						Roles__c,
						Name__c,
						Email__c,
						SigningGroupId__c,
						SigningGroupName__c,
						SmsPhoneNumber__c,
						AccessCode__c,
						IdCheckRequired__c,
						Note__c,
						Language__c,
						EmailSubject__c,
						EmailMessage__c,
						HostName__c,
						HostEmail__c,
						SignNow__c,
						SourceId__c,
						ReadOnly__c,
						Required__c
					FROM Recipients__r
					ORDER BY Sequence__c ASC NULLS LAST
				)
				FROM EnvelopeConfiguration__c
				WHERE Id = :envelopeConfigurationId
				WITH SECURITY_ENFORCED
				LIMIT 1
			]));
		}

		public List<EnvelopeConfiguration.Listing> queryEnvelopeConfigurations() {
			List<EnvelopeConfiguration.Listing> configurationList = new List<EnvelopeConfiguration.Listing>();
			for (EnvelopeConfiguration__c template : [
				SELECT Id, Name, SourceObject__c, LastModifiedDate
				FROM EnvelopeConfiguration__c
				WITH SECURITY_ENFORCED
				ORDER BY LastModifiedDate DESC
				LIMIT 50000
			]) {
				configurationList.add(new EnvelopeConfiguration.Listing(
					template.Id,
					template.Name,
					template.SourceObject__c,
					template.LastModifiedDate));
			}
			return configurationList;
		}

		public EnvelopeConfiguration updateEnvelopeConfiguration(final EnvelopeConfiguration envelopeConfiguration) {
			Permissions.verifyIsUpdateable(EnvelopeConfiguration__c.getSObjectType(), new List<String> {
				'Name',
				Application.namespacePrefix + 'CustomFields__c',
				Application.namespacePrefix + 'DocuSignId__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'IsDraft__c',
				Application.namespacePrefix + 'MergeFields__c',
				Application.namespacePrefix + 'Notifications__c',
				Application.namespacePrefix + 'SenderPermissions__c',
				Application.namespacePrefix + 'SourceObject__c'
			});
			Permissions.verifyIsCreateable(EnvelopeConfigurationDocument__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'Filter__c',
				Application.namespacePrefix + 'Name__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});
			Permissions.verifyIsUpdateable(EnvelopeConfigurationDocument__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Extension__c',
				Application.namespacePrefix + 'Filter__c',
				Application.namespacePrefix + 'Name__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});
			Permissions.verifyIsCreateable(EnvelopeConfigurationRecipient__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'EnvelopeConfiguration__c',
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'Filter__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'IncrementRoutingOrder__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Name__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Relationship__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Roles__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});
			Permissions.verifyIsUpdateable(EnvelopeConfigurationRecipient__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'Filter__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'IncrementRoutingOrder__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Name__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Relationship__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Roles__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			List<EnvelopeConfigurationDocument__c> documents = null;
			List<EnvelopeConfigurationRecipient__c> recipients = null;

			if (envelopeConfiguration != null && envelopeConfiguration.id != null) {
				update convert(envelopeConfiguration, true);
				EnvelopeConfiguration currentConfiguration = getEnvelopeConfiguration(envelopeConfiguration.id);

				documents = convert(envelopeConfiguration.id, envelopeConfiguration.documents);
				delete convert(envelopeConfiguration.id, currentConfiguration.documents);
				insert documents;

				recipients = convert(envelopeConfiguration.id, envelopeConfiguration.recipients);
				delete convert(envelopeConfiguration.id, currentConfiguration.recipients);
				insert recipients;
			}

			return (EnvelopeConfiguration)envelopeConfiguration
				.withDocuments(convert(documents))
				.withRecipients(convert(recipients));
		}

		public UUID queryDocuSignId(final Id envelopeConfigurationId) {
			EnvelopeConfiguration__c ec = (EnvelopeConfiguration__c)Collection.head([
				SELECT DocuSignId__c
				FROM EnvelopeConfiguration__c
				WHERE Id = :envelopeConfigurationId
				WITH SECURITY_ENFORCED
				LIMIT 1
			]);
			return ec == null || String.isBlank(ec.DocuSignId__c) ? null : UUID.tryParse(ec.DocuSignId__c);
		}

		public Boolean deleteEnvelopeConfiguration(final Id envelopeConfigurationId) {
			Permissions.verifyIsDeletable(EnvelopeConfiguration__c.getSObjectType());
			Permissions.verifyIsDeletable(EnvelopeConfigurationDocument__c.getSObjectType());
			Permissions.verifyIsDeletable(EnvelopeConfigurationRecipient__c.getSObjectType());

			Boolean result = false;
			if (envelopeConfigurationId != null) {
				List<EnvelopeConfiguration__c> toDelete = [
					SELECT Id
					FROM EnvelopeConfiguration__c
					WHERE Id = :envelopeConfigurationId
					LIMIT 1
				];
				if (Collection.isNotEmpty(toDelete)) {
					delete toDelete;
					result = true;
				}
			}
			return result;
		}

		public Boolean deleteContentDocuments(final List<Id> contentDocumentIds) {
			Permissions.verifyIsDeletable(CONTENT_DOCUMENT_TYPE);

			Boolean result = false;
			if (Collection.isNotEmpty(contentDocumentIds)) {
				delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
				result = true;
			}
			return result;
		}
	}

	@TestVisible
	private static ValidationResult validate(
		final Document document,
		final Integer index) {

		if (document == null) {
			return new ValidationResult(String.format(Label.ArrayError_3, new List<Object> {
				Label.DocumentElements,
				index,
				Label.UndefinedDocument
			}));
		}

		ValidationResult result = new ValidationResult();
		if (document instanceof EnvelopeConfiguration.TemplateDocument) {
			EnvelopeConfiguration.TemplateDocument td = (EnvelopeConfiguration.TemplateDocument)document;
			if (!StringUtils.isValidId(td.sourceId)
				|| ((Id)td.sourceId).getSobjectType() != ContentDocument.getSObjectType()) {

				result.add(String.format(Label.ArrayError_3, new List<Object> {
					Label.DocumentElements,
					index,
					Label.InvalidContentDocumentSource
				}));
			}
			if (String.isBlank(td.name)) {
				result.add(String.format(Label.ArrayError_3, new List<Object> {
					Label.DocumentElements,
					index,
					Label.UndefinedName
				}));
			}
			if (String.isBlank(td.extension)) {
				result.add(String.format(Label.ArrayError_3, new List<Object> {
					Label.DocumentElements,
					index,
					Label.UndefinedExtension
				}));
			} else if (!DocumentService.isValidFileType(td.extension)) {
				result.add(String.format(Label.ArrayError_3, new List<Object> {
					Label.DocumentElements,
					index,
					Label.InvalidFileType
				}));
			}
		} else if (!(document instanceof EnvelopeConfiguration.SourceFiles)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.DocumentElements,
				index,
				Label.InvalidType
			}));
		}
		return result;
	}

	@TestVisible
	private static ValidationResult validate(
		final Query.Relationship relationship,
		final Integer index,
		final DescribeSObjectResult sourceDescribe,
		final Boolean expectLookup) {

		if (relationship == null) {
			return new ValidationResult(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				Label.UndefinedRelationship
			}));
		}

		ValidationResult result = new ValidationResult();
		if (relationship.isLookup != expectLookup) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				Label.InvalidRelationshipType
			}));
		}

		if (String.isBlank(relationship.name)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				Label.UndefinedRelationshipName
			}));
		}

		if (String.isBlank(relationship.relatesTo)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				Label.UndefinedRelatedObject
			}));
		} else if (!Salesforce.isValidSObject(relationship.relatesTo)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				String.format(Label.InvalidRelatedObject_1, new List<Object> { relationship.relatesTo })
			}));
		} else if (!RecipientService.canResolveRelatedRecipients(Salesforce.getSObjectType(relationship.relatesTo))) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				String.format(Label.UnsupportedRelatedObject_1, new List<Object> { relationship.relatesTo })
			}));
		} else if (sourceDescribe != null) {
			Boolean foundRelationship = false, typeMatch = false;
			if (expectLookup) {
				for (SObjectField f : sourceDescribe.fields.getMap().values()) {
					DescribeFieldResult df = f.getDescribe();
					if (df.getRelationshipName() == relationship.name) {
						foundRelationship = true;
						typeMatch = (SObjectType)Collection.head(df.getReferenceTo())
							== Salesforce.getSObjectType(relationship.relatesTo);
						break;
					}
				}
			} else {
				for (ChildRelationship cr : sourceDescribe.getChildRelationships()) {
					if (cr.getRelationshipName() == relationship.name) {
						foundRelationship = true;
						typeMatch = cr.getChildSObject() == Salesforce.getSObjectType(relationship.relatesTo);
						break;
					}
				}
			}

			if (!foundRelationship || !typeMatch) {
				result.add(String.format(Label.ArrayError_3, new List<Object> {
					Label.RecipientElements,
					index,
					String.format(Label.InvalidRelationship_1, new List<Object> { relationship.name })
				}));
			}
		}
		return result;
	}

	@TestVisible
	private static ValidationResult validate(
		final Recipient recipient,
		final Integer index,
		final DescribeSObjectResult sourceDescribe) {

		if (recipient == null) {
			return new ValidationResult(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				Label.UndefinedRecipient
			}));
		}

		ValidationResult result = new ValidationResult();
		Id sourceId = recipient.getSourceId();
		Boolean validateSource = String.isNotBlank(sourceId);
		if (recipient instanceof EnvelopeConfiguration.LookupRecipient) {
			validateSource = false; // Source is determined at envelope generation time
			EnvelopeConfiguration.LookupRecipient lr = (EnvelopeConfiguration.LookupRecipient)recipient;
			result.add(validate(lr.relationship, index, sourceDescribe, true));
		} else if (recipient instanceof EnvelopeConfiguration.RelatedRecipients) {
			validateSource = false; // Source is determined at envelope generation time
			EnvelopeConfiguration.RelatedRecipients rrs = (EnvelopeConfiguration.RelatedRecipients)recipient;
			result.add(validate(rrs.relationship, index, sourceDescribe, false));
		} else if (String.isBlank(recipient.email)
			&& !recipient.isSigningGroup
			&& !recipient.hasRole) {

			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				Label.PlaceholderRecipientMustHaveRole
			}));
		}

		if (validateSource && !RecipientService.canResolveRecipientType(sourceId.getSobjectType())) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.RecipientElements,
				index,
				String.format(Label.CannotResolveRecipientSource_1, new List<Object> { sourceId.getSobjectType() })
			}));
		}
		return result;
	}

	@TestVisible
	private static ValidationResult validate(
		final CustomField customField,
		final Integer index) {

		if (customField == null) {
			return new ValidationResult(String.format(Label.ArrayError_3, new List<Object> {
				Label.CustomFieldElements,
				index,
				Label.UndefinedCustomField
			}));
		}

		ValidationResult result = new ValidationResult();
		if (String.isBlank(customField.name)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.CustomFieldElements,
				index,
				Label.UndefinedName
			}));
		}

		if (customField.required && !customField.show && String.isBlank(customField.value)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.CustomFieldElements,
				index,
				Label.UndefinedCustomFieldValue
			}));
		}

		if (customField.isList && Collection.isEmpty(customField.items)) {
			result.add(String.format(Label.ArrayError_3, new List<Object> {
				Label.CustomFieldElements,
				index,
				Label.UndefinedList
			}));
		}

		return result;
	}

	@TestVisible
	private static ValidationResult validate(
		final EnvelopeConfiguration ec,
		final Boolean forUpdate) {

		if (ec == null) {
			return new ValidationResult(Label.UndefinedEnvelopeConfiguration);
		}

		ValidationResult result = new ValidationResult();
		if (forUpdate && String.isBlank(ec.id)) {
			result.add(Label.UndefinedId);
		}

		if (String.isBlank(ec.name)) {
			result.add(Label.UndefinedName);
		}

		DescribeSObjectResult sourceDescribe = null;
		if (String.isBlank(ec.sourceObject)) {
			result.add(Label.UndefinedSourceObject);
		} else if (!Salesforce.isValidSObject(ec.sourceObject)) {
			result.add(Label.InvalidSourceObject);
		} else {
			sourceDescribe = Salesforce.getSObjectType(ec.sourceObject).getDescribe();
		}

		if (Collection.isNotEmpty(ec.documents)) {
			for (Integer i = 0; i < ec.documents.size(); i++) {
				result.add(validate(ec.documents[i], i));
			}
		}

		if (Collection.isNotEmpty(ec.recipients)) {
			for (Integer i = 0; i < ec.recipients.size(); i++) {
				result.add(validate(ec.recipients[i], i, sourceDescribe));
			}
		}

		if (Collection.isNotEmpty(ec.customFields)) {
			for (Integer i = 0; i < ec.customFields.size(); i++) {
				result.add(validate(ec.customFields[i], i));
			}
		}

		return result;
	}

	@TestVisible
	private static List<Document> getTemplateDocuments(final List<Document> documents) {
		List<Document> result = new List<Document>();
		if (documents != null) {
			Integer sequence = 0;
			for (Document d : documents) {
				if (d != null && d instanceof EnvelopeConfiguration.TemplateDocument) {
					result.add(d.copy().withSequence(++sequence));
				}
				// Source files are ignored as they cannot be represented in a DS template.
			}
		}
		return result;
	}

	@TestVisible
	private static List<Recipient> getTemplateRecipients(final List<Recipient> recipients) {
		List<Recipient> result = new List<Recipient>();
		if (recipients != null) {
			Integer sequence = 0;
			for (Recipient r : recipients) {
				if (r == null) continue;

				if (r instanceof EnvelopeConfiguration.RelatedRecipients) {
					Integer routingOrder = r.routingOrder > 0 ? r.routingOrder : 1;
					EnvelopeConfiguration.RelatedRecipients rrs = (EnvelopeConfiguration.RelatedRecipients)r;
					if (Collection.size(rrs.roles) > 1) {
						for (String role : rrs.roles) {
							result.add(r.copy()
								.withSequence(++sequence)
								.withRole(role)
								.withRoutingOrder(rrs.incrementRoutingOrder ? routingOrder++ : routingOrder));
						}
					} else {
						result.add(r.copy()
							.withSequence(++sequence)
							.withRoutingOrder(routingOrder));
					}
				} else {
					result.add(r.copy().withSequence(++sequence));
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Template getTemplate(final EnvelopeConfiguration ec) {
		if (ec == null) return null;

		return new Template(
			ec.docuSignId,
			ec.name,
			ec.customFields,
			ec.notifications,
			ec.emailSubject,
			ec.emailMessage,
			getTemplateDocuments(ec.documents),
			getTemplateRecipients(ec.recipients),
			Datetime.now());
	}

	@TestVisible
	private static List<Recipient> mergeRecipients(final List<Recipient> recipients) {
		if (recipients == null) return new List<Recipient>();

		// Build list to query
		Map<SObjectType, Set<Id>> toQuery = new Map<SObjectType, Set<Id>>();
		for (Recipient r : recipients) {
			if (r == null) continue;

			Id sourceId = r.getSourceId();
			if (String.isNotBlank(sourceId)) {
				SObjectType type = sourceId.getSobjectType();
				if (toQuery.containsKey(type)) {
					toQuery.get(type).add(sourceId);
				} else {
					toQuery.put(type, new Set<Id> { sourceId });
				}
			}
		}

		// Query the Salesforce recipients
		Map<Id, Recipient> toMerge = new Map<Id, Recipient>();
		for (SObjectType t : toQuery.keySet()) {
			for (Recipient r : RecipientService.resolveRecipients(t, toQuery.get(t))) {
				if (r == null) continue;

				Id sourceId = r.getSourceId();
				if (String.isNotBlank(sourceId)) toMerge.put(sourceId, r);
			}
		}

		// Merge the Salesforce recipients
		List<Recipient> result = new List<Recipient>();
		for (Recipient r : recipients) {
			if (r == null) continue;

			Id sourceId = r.getSourceId();
			if (String.isNotBlank(sourceId) && toMerge.containsKey(sourceId)) {
				result.add(mergeRecipient(
					r,
					toMerge.get(sourceId),
					r.routingOrder,
					r.getRoleName()));
			} else {
				result.add(r);
			}
		}
		return result;
	}

	public static EnvelopeConfiguration createEnvelopeConfiguration(final EnvelopeConfiguration envelopeConfiguration) {
		Permissions.verifyIsDocuSignAdministrator();

		ValidationResult vr = validate(envelopeConfiguration, false);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelopeConfiguration, vr);

		try {
			Template template = EnvelopeAPI.getInstance().createTemplate(getTemplate(envelopeConfiguration));
			envelopeConfiguration.withDocuSignId(template.id);

			return DB.insertEnvelopeConfiguration(envelopeConfiguration);
		} finally {
			Credentials.save();
		}
	}

	public static Url getTemplateEditUrl(
		final UUID docuSignId,
		final Url returnUrl) {

		Permissions.verifyIsDocuSignAdministrator();

		if (docuSignId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		try {
			return EnvelopeAPI.getInstance().getTemplateEditUrl(docuSignId, returnUrl);
		} finally {
			Credentials.save();
		}
	}

	public static EnvelopeConfiguration getEnvelopeConfiguration(final Id envelopeConfigurationId) {
		Permissions.verifyIsDocuSignAdministrator();

		if (envelopeConfigurationId == null) throw new DocuSignException(Label.UndefinedId);

		EnvelopeConfiguration ec = DB.queryEnvelopeConfiguration(envelopeConfigurationId);
		if (ec == null) throw new DocuSignException(Label.EnvelopeConfigurationNotFound);

		return ec.withRecipients(mergeRecipients(ec.recipients));
	}

	public static List<EnvelopeConfiguration.Listing> queryEnvelopeConfigurationsForDisplay() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryEnvelopeConfigurations();
	}

	public static EnvelopeConfiguration updateEnvelopeConfiguration(final EnvelopeConfiguration envelopeConfiguration) {
		Permissions.verifyIsDocuSignAdministrator();

		ValidationResult vr = validate(envelopeConfiguration, true);
		if (!vr.isValid) throw new ValidationException(Label.InvalidEnvelopeConfiguration, vr);

		try {
			Template template = getTemplate(envelopeConfiguration);
			if (template.id == null) {
				template = EnvelopeAPI.getInstance().createTemplate(template);
				envelopeConfiguration.withDocuSignId(template.id);
			} else {
				EnvelopeAPI.getInstance().updateTemplate(template);
			}

			return DB.updateEnvelopeConfiguration(envelopeConfiguration);
		} finally {
			Credentials.save();
		}
	}

	public static Boolean deleteContentDocuments(final List<Id> contentDocumentIds) {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.deleteContentDocuments(contentDocumentIds);
	}

	public static Boolean deleteEnvelopeConfiguration(final Id envelopeConfigurationId) {
		Permissions.verifyIsDocuSignAdministrator();

		if (envelopeConfigurationId == null) throw new DocuSignException(Label.UndefinedId);

		try {
			UUID templateId = DB.queryDocuSignId(envelopeConfigurationId);
			if (templateId != null) {
				EnvelopeAPI.getInstance().deleteTemplate(templateId);
			}

			return DB.deleteEnvelopeConfiguration(envelopeConfigurationId);
		} finally {
			Credentials.save();
		}
	}

	@TestVisible
	private static List<Document> resolveDocuments(
		final Entity source,
		final List<Document> documents) {

		List<Document> result = new List<Document>();
		if (documents != null) {
			for (Document d : documents) {
				if (d == null || d instanceof EnvelopeConfiguration.TemplateDocument) continue; // template added elsewhere

				if (d instanceof EnvelopeConfiguration.SourceFiles) {
					if (source != null && source.id != null) {
						EnvelopeConfiguration.SourceFiles sfs = (EnvelopeConfiguration.SourceFiles)d;
						result.addAll(DocumentService.getLinkedDocuments(
							ContentVersion.getSObjectType(),
							new Set<Id> { source.id },
							sfs.filter));
					} // else skip these files
				} else {
					result.add(d.copy()); // base documents added without modification
				}
			}

			Integer sequence = 1; // First document is template
			for (Document d : result) {
				d.withSequence(++sequence);
			}
		}
		return result;
	}

	private static Recipient mergeRecipient(
		final Recipient templateRecipient,
		final Recipient envelopeRecipient,
		final Integer routingOrder,
		final String role) {

		if (envelopeRecipient == null) return templateRecipient;
		if (templateRecipient == null) return envelopeRecipient;

		return envelopeRecipient
			.withId(templateRecipient.id)
			.withType(templateRecipient.type, templateRecipient.signNow)
			.withRoutingOrder(routingOrder)
			.withRole(role)
			.withAuthentication(templateRecipient.authentication)
			.withNote(templateRecipient.note)
			.withEmailSettings(templateRecipient.emailSettings)
			.withHost(templateRecipient.hostName, templateRecipient.hostEmail, templateRecipient.signNow)
			.withTabs(templateRecipient.tabs)
			.withPermissions(templateRecipient.readOnly, templateRecipient.required);
	}

	private static Recipient resolveLookupRecipient(
		final EnvelopeConfiguration.LookupRecipient templateRecipient,
		final Entity source) {

		Recipient result = null;
		if (templateRecipient != null
			&& source != null
			&& source.isValid
			&& templateRecipient.relationship != null
			&& String.isNotBlank(templateRecipient.relationship.name)) {

			Recipient recipient = (Recipient)Collection.head(RecipientService.getRelatedRecipients(
				source.type,
				new Set<Id> { source.id },
				templateRecipient.relationship,
				null));
			if (recipient != null) {
				result = mergeRecipient(
					templateRecipient,
					recipient,
					templateRecipient.routingOrder,
					templateRecipient.getRoleName());
			}
		}
		return result;
	}

	@TestVisible
	private static List<Recipient> resolveRelatedRecipients(
		final EnvelopeConfiguration.RelatedRecipients templateRecipient,
		final Entity source) {

		List<Recipient> result = new List<Recipient>();
		if (templateRecipient != null
			&& source != null
			&& source.isValid
			&& templateRecipient.relationship != null
			&& String.isNotBlank(templateRecipient.relationship.name)) {

			Set<String> templateRoles = templateRecipient.roles == null
				? new Set<String>() : new Set<String>(templateRecipient.roles);

			// Query the related recipients
			List<Recipient> recipients = RecipientService.getRelatedRecipients(
				source.type,
				new Set<Id> { source.id },
				templateRecipient.relationship,
				templateRecipient.filter);
			if (recipients == null) recipients = new List<Recipient>();

			// Map the result roles (if any) to the recipient.
			Map<String, Recipient> roleRecipients = new Map<String, Recipient>();
			List<Recipient> nonRoleRecipients = new List<Recipient>();
			for (Recipient r : recipients) {
				String role = r.getRoleName();
				if (String.isNotBlank(role)
					&& templateRoles.contains(role)
					&& !roleRecipients.containsKey(role)) {

					roleRecipients.put(role, r);
				} else {
					nonRoleRecipients.add(r);
				}
			}

			// Loop through template roles, mapping any source recipients by role name.
			Integer routingOrder = templateRecipient.routingOrder > 0 ? templateRecipient.routingOrder : 1;
			for (String role : templateRecipient.roles) {
				Recipient envelopeRecipient;
				if (roleRecipients.containsKey(role)) {
					envelopeRecipient = (Recipient)roleRecipients.remove(role);
				} else if (!nonRoleRecipients.isEmpty()) { // take the first available recipient
					envelopeRecipient = nonRoleRecipients.remove(0);
				} else { // Add placeholder recipient
					envelopeRecipient = templateRecipient.copy();
				}

				result.add(mergeRecipient(
					templateRecipient,
					envelopeRecipient,
					templateRecipient.incrementRoutingOrder ? routingOrder++ : routingOrder,
					role));
			}
		}
		return result;
	}

	private static List<Recipient> resolveRecipients(
		final Entity source,
		final List<Recipient> recipients) {

		List<Recipient> result = new List<Recipient>();
		if (recipients != null) {
			for (Recipient r : mergeRecipients(recipients)) {
				if (r == null) continue;

				if (r instanceof EnvelopeConfiguration.LookupRecipient) {
					Recipient recipient = resolveLookupRecipient(
						(EnvelopeConfiguration.LookupRecipient)r,
						source);
					if (recipient != null) result.add(recipient);
				} else if (r instanceof EnvelopeConfiguration.RelatedRecipients) {
					result.addAll(resolveRelatedRecipients(
						(EnvelopeConfiguration.RelatedRecipients)r,
						source));
				} else {
					result.add(r.copy()); // base recipients added without modification
				}
			}

			// Sort and set incrementing sequence.
			result.sort();
			Integer sequence = 0;
			for (Recipient r : result) {
				r.withSequence(++sequence);
			}
		}
		return result;
	}

	private static Map<String, Map<String, String>> parseMergeFields(final Envelope envelope) {
		Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
		if (envelope != null) {
			result = MergeService.parseFields(envelope.emailSubject, result);
			result = MergeService.parseFields(envelope.emailMessage, result);

			if (envelope.recipients != null) {
				for (Recipient r : envelope.recipients) {
					if (r == null) continue;

					if (r.emailSettings != null) {
						result = MergeService.parseFields(r.emailSettings.subject, result);
						result = MergeService.parseFields(r.emailSettings.message, result);
					}
					result = MergeService.parseFields(r.note, result);
				}
			}

			if (envelope.customFields != null) {
				for (CustomField cf : envelope.customFields) {
					if (cf != null) result = MergeService.parseFields(cf.value, result);
				}
			}
		}
		return result;
	}

	private static Envelope mergeData(
		final Envelope envelope,
		final Map<String, String> mergeData) {

		if (envelope == null || Collection.isEmpty(mergeData)) return envelope;

		if (envelope.recipients != null) {
			for (Recipient r : envelope.recipients) {
				if (r.emailSettings != null) {
					r.withEmailSettings(new Recipient.EmailSettings(
						r.emailSettings.language,
						r.emailSettings.languageLabel,
						MergeService.mergeData(r.emailSettings.subject, mergeData, r),
						MergeService.mergeData(r.emailSettings.message, mergeData, r)));
				}
				r.withNote(MergeService.mergeData(r.note, mergeData, r));
			}
		}

		if (envelope.customFields != null) {
			for (CustomField cf : envelope.customFields) {
				if (cf != null) cf.withValue(MergeService.mergeData(cf.value, mergeData, null));
			}
		}

		return envelope.withEmail(
			MergeService.mergeData(envelope.emailSubject, mergeData, null),
			MergeService.mergeData(envelope.emailMessage, mergeData, null));
	}

	@TestVisible
	private static Envelope resolveMergeData(
		final Entity source,
		final Envelope envelope) {

		if (envelope == null) return null;

		// First parse out all the fields.
		Map<String, Map<String, String>> mergeFields = parseMergeFields(envelope);

		// Query the merge fields.
		Map<String, String> mergeData = MergeService.resolveFields(
			source == null ? null : source.id,
			mergeFields);

		// Finally replace the merge fields with data.
		return mergeData(envelope, mergeData);
	}

	public static Envelope getEnvelope(
		final Id envelopeConfigurationId,
		final Entity source) {

		Permissions.verifyIsDocuSignSender();

		if (envelopeConfigurationId == null) throw new DocuSignException(Label.UndefinedEnvelopeConfiguration);

		EnvelopeConfiguration ec = DB.queryEnvelopeConfiguration(envelopeConfigurationId);
		if (ec == null) throw new DocuSignException(Label.EnvelopeConfigurationNotFound);
		if (source != null && source.typeName != ec.sourceObject) {
			throw new DocuSignException(String.format(Label.SourceMismatch_2, new List<Object> {
				source.typeName, ec.sourceObject
			}));
		}

		Recipient.EmailSettings defaultEmail = Localization.getEmailSettingsForCurrentLanguage();
		Envelope result = new Envelope(
			ec.notifications,
			String.isBlank(ec.emailSubject) ? defaultEmail.subject : ec.emailSubject,
			String.isBlank(ec.emailMessage) ? defaultEmail.message : ec.emailMessage,
			source)
			.withEnvelopeConfigurationId(envelopeConfigurationId);

		if (ec.docuSignId != null) {
			// Set DS template to the first document.
			result.addDocuments(new List<Document> {
				Document.fromTemplate(ec.docuSignId, ec.name)
					.withSequence(1)
					.withPermissions(true, true)
			});
		}

		// Load documents from source, etc.
		result = result.addDocuments(resolveDocuments(
			source,
			ec.documents));

		// Load recipients from source, related lists, lookups.
		result = result.addRecipients(resolveRecipients(
			source,
			ec.recipients));

		// Resolve merge data
		result = resolveMergeData(source, result);

		// Set other envelope properties
		if (Collection.isNotEmpty(ec.customFields)) {
			List<CustomField> customFields = new List<CustomField>();
			for (CustomField cf : ec.customFields) {
				customFields.add(cf.copy());
			}
			result = result.withCustomFields(customFields);
		}
		result = result.withSenderPermissions(ec.senderPermissions.copy());
		result = result.withOptions(ec.options.copy());

		return result;
	}
}
