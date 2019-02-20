/**
 * Interface for SObject entity resolution.
 */
public interface EntityResolver {

	/**
	 * Tests whether an SObject type can be resolved by this implementation.
	 *
	 * @param type The SObject type.
	 *
	 * @return True if this implementation can resolve the SObject type, false otherwise.
	 */
	Boolean canResolve(SObjectType type);

	/**
	 * Resolves an SObject's label, name, and parent by ID.
	 *
	 * @param id The SObject ID.
	 *
	 * @return The resolved entity.
	 */
	Entity resolve(Id id);
}