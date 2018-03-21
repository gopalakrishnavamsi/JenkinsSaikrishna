/**
 * Interface for envelope recipient resolution.
 */
public interface RecipientResolver {

	/**
	 * Tests whether a recipient SObject type can be resolved by this implementation.
	 *
	 * @param sObjectType The SObject type name.
	 *
	 * @return True if this implementation can resolve the SObject type, false otherwise.
	 */
	Boolean canResolve(String sObjectType);

	/**
	 * Resolves an SObject to a recipient.
	 *
	 * @param sObjectType The SObject type name.
	 * @param sObjectId The SObject ID.
	 *
	 * @return The resolved recipient.
	 */
	Recipient resolve(String sObjectType, Id sObjectId);
}
