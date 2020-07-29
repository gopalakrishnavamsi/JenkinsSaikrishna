@IsTest
public class MockRequest {

	public String method { get; private set; }
	public String apiVersion { get; private set; }
	public UUID accountId { get; private set; }
	public String resource { get; private set; }
	public List<Object> path { get; private set; }
	public QueryString parameters { get; private set; }
	public String userAgent { get; private set; }
	public String body { get; private set; }

	public MockRequest(
		final String method,
		final String apiVersion,
		final UUID accountId,
		final String resource,
		final List<Object> path,
		final QueryString parameters,
		final String userAgent,
		final String body) {

		this.method = method;
		this.apiVersion = apiVersion;
		this.accountId = accountId;
		this.resource = resource;
		this.path = path;
		this.parameters = parameters == null ? QueryString.empty : parameters;
		this.userAgent = userAgent;
		this.body = body;
	}
}