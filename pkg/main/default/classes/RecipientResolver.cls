/**
 * Interface for envelope recipient resolution.
 */
public interface RecipientResolver {
	/**
	 * Tests whether recipients can be resolved by the source SObject type.
	 *
	 * @param type The SObject type.
	 *
	 * @return True if this implementation can resolve recipients from the source SObject type, false otherwise.
	 */
	Boolean canResolveRecipients(SObjectType type);

	/**
	 * Tests whether recipient SObjects can be searched.
	 *
	 * @param type The SObject type.
	 *
	 * @return True if this implementation can search the recipient SObject.
	 */
	Boolean canSearchRecipients(SObjectType type);

	/**
	 * Reads recipients from SObjects.
	 *
	 * @param type The SObject type.
	 * @param ids The source SObject IDs.
	 *
	 * @return The resolved recipients.
	 */
	List<Recipient> getRecipients(SObjectType type, Set<Id> ids);

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
	List<Recipient> searchRecipients(SObjectType type, String firstName, String lastName,
		Recipient.SearchBehavior behavior);
}