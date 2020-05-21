/**
 * Interface for envelope recipient resolution.
 */
public interface RecipientResolver {
	/**
	 * Tests whether related recipients can be resolved by the target SObject type. For example, <code>Contact</code> or
	 * <code>OpportunityContactRole</code>.
	 *
	 * @param type The related list SObject type.
	 *
	 * @return True if this implementation can resolve recipients from the target SObject type, false otherwise.
	 */
	Boolean canResolveRelatedRecipients(SObjectType type);

	/**
	 * Tests whether recipients can be resolved by the envelope source SObject type.
	 *
	 * @param type The envelope source SObject type.
	 *
	 * @return True if this implementation can resolve recipients from the source SObject type, false otherwise.
	 */
	Boolean canResolveSourceRecipients(SObjectType type);

	/**
	 * Tests whether recipient SObjects can be searched or directly queried. These are discrete Salesforce entities that
	 * can be added to an envelope. <code>User</code> and <code>Contact</code> are examples.
	 *
	 * @param type The recipient SObject type.
	 *
	 * @return True if this implementation can search or directly query the recipient SObject.
	 */
	Boolean canResolveRecipientType(SObjectType type);

	/**
	 * Reads recipients from SObjects using default rules.
	 *
	 * @param type The SObject type.
	 * @param ids The source SObject IDs.
	 *
	 * @return The resolved recipients.
	 */
	List<Recipient> getSourceRecipients(
		SObjectType type,
		Set<Id> ids);

	/**
	 * Reads recipients related to a type.
	 *
	 * @param type The source SObject type.
	 * @param ids The source SObject IDs.
	 * @param relationship The relationship to query.
	 * @param filter Optional result filter.
	 *
	 * @return The resolved recipients.
	 */
	List<Recipient> getRelatedRecipients(
		SObjectType type,
		Set<Id> ids,
		Query.Relationship relationship,
		Query.Filter filter);

	/**
	 * Retrieves a list of recipients by name.
	 *
	 * @param type The SObject type.
	 * @param firstName The first name to search. The only search term honored for compound searches.
	 * @param lastName The last name to search. Ignored for compound searches.
	 * @param behavior How the search is performed. This may be overridden at runtime if predicate fields do not support
	 * filtering.
	 *
	 * @return The recipients matching the search criteria.
	 */
	List<Recipient> searchRecipients(
		SObjectType type,
		String firstName,
		String lastName,
		Recipient.SearchBehavior behavior);

	/**
	 * Retrieves a list of recipients by ID.
	 *
	 * @param type The SObject type
	 * @param ids The source SObject IDs.
	 *
	 * @return The resolved recipients.
	 */
	List<Recipient> getRecipients(
		SObjectType type,
		Set<Id> ids);
}
