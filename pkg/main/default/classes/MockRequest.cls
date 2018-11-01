@IsTest
public class MockRequest {
	public String method { get; private set; }
	public String apiVersion { get; private set; }
	public UUID accountId { get; private set; }
	public String resource { get; private set; }
	public List<String> path { get; private set; }
	public QueryString parameters { get; private set; }
	public String body { get; private set; }

	public MockRequest(
		final String method,
		final String apiVersion,
		final UUID accountId,
		final String resource,
		final List<String> path,
		final QueryString parameters,
		final String body) {

		this.method = method;
		this.apiVersion = apiVersion;
		this.accountId = accountId;
		this.resource = resource;
		this.path = path;
		this.parameters = parameters;
		this.body = body;
	}
}