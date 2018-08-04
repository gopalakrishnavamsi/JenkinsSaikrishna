/**
	Centralized logic to deal with query string parameters.
*/
public virtual class QueryString {

	public static final String PARAM_SOURCE_ID = 'sId';
	public static final String PARAM_ENVELOPE_ID = 'eId';
	public static final String PARAM_DOCUSIGN_ACTION = 'dsAction';
	public static final QueryString empty = new QueryString(new Map<String, String>());

	private final Map<String, String> qs;
	public Set<String> keys {
		get {
			return qs.keySet();
		}
	}

	public QueryString(final Map<String, String> queryString) {
		this.qs = new Map<String, String>();
		if (queryString != null) {
			for (String key : queryString.keySet()) {
				String value = queryString.get(key);
				if (String.isNotBlank(value)) {
					this.qs.put(key, value);
				}
			}
		}
	}

	public QueryString(final String key, final String value) {
		this(new Map<String, String> { key => value });
	}

	public static QueryString fromCurrentPage() {
		if (ApexPages.currentPage() == null) return QueryString.empty;

		return new QueryString(ApexPages.currentPage().getParameters());
	}

	public static QueryString fromString(final String s) {
		if (String.isBlank(s)) return QueryString.empty;

		final Map<String, String> qs = new Map<String, String>();
		final List<String> kvs = s.split('&');
		for (String kv : kvs) {
			final List<String> toks = kv.split('=');
			if (toks != null && toks.size() >= 2)
				qs.put(StringUtils.decode(toks[0]), StringUtils.decode(toks[1]));
		}

		return new QueryString(qs);
	}

	public Boolean isEmpty() {
		return qs == null || qs.isEmpty();
	}

	public Boolean isDefined(final String key) {
		return String.isNotBlank(key) && String.isNotBlank(qs.get(key));
	}

	private String getValue(final String key) {
		if (String.isBlank(key)) {
			throw new DocuSignException(Label.InvalidUrlParameter);
		}

		final String value = qs.get(key);
		if (String.isBlank(value)) {
			throw new DocuSignException(Label.InvalidUrlParameter);
		}

		return value;
	}

	public String get(final String key) {
		return qs.get(key);
	}

	public Boolean getBoolean(final String key) {
		Boolean result;
		final String value = getValue(key);

		if (value == '0' || value.equalsIgnoreCase('false')) result = false; else if (value == '1' || value.equalsIgnoreCase('true')) result = true; else throw new DocuSignException(Label.InvalidUrlParameter);

		return result;
	}

	/**
	* Return the boolean value from an URL parameter. A default value must be provided.
	*
	* @key String the name of the URL parameter
	* @defaultValue Boolean the default value
	* @return Boolean the boolean value of the URL parameter
	*/
	public Boolean getBoolean(final String key, final Boolean defaultValue) {
		Boolean result = defaultValue;
		final String value = get(key);

		if (String.isNotBlank(value)) {
			if (value == '0' || value.equalsIgnoreCase('false')) result = false; else if (value == '1' || value.equalsIgnoreCase('true')) result = true;
		}

		return result;
	}

	public Id getId(final String key) {
		Id result;
		final String value = getValue(key);

		try {
			result = Id.valueOf(value);
		} catch (Exception ex) {
			throw new DocuSignException(Label.InvalidUrlParameter, ex);
		}

		return result;
	}

	public Id getId(final String key, final Id defaultValue) {
		Id result = defaultValue;
		final String value = get(key);

		try {
			result = Id.valueOf(value);
		} catch (Exception ex) {
		}

		return result;
	}

	public Integer getInteger(final String key) {
		Integer result;
		final String value = getValue(key);

		try {
			result = Integer.valueOf(value);
		} catch (Exception ex) {
			throw new DocuSignException(Label.InvalidUrlParameter, ex);
		}

		return result;
	}

	public Integer getInteger(final String key, final Integer defaultValue) {
		Integer result = defaultValue;
		final String value = get(key);

		try {
			result = Integer.valueOf(value);
		} catch (Exception ex) {
		}

		return result;
	}

	public String getString(final String key) {
		return getValue(key).unescapeJava();
	}

	public String getString(final String key, final String defaultValue) {
		String result = defaultValue;
		final String value = get(key);

		if (String.isNotBlank(value)) result = value.unescapeJava();

		return result;
	}

	public UUID getUUID(final String key) {
		UUID result;
		final String value = getValue(key);

		try {
			result = UUID.parse(value);
		} catch (Exception ex) {
			throw new DocuSignException(Label.InvalidUrlParameter, ex);
		}

		return result;
	}

	public UUID getUUID(final String key, final UUID defaultValue) {
		UUID result = defaultValue;
		final String value = get(key);

		try {
			result = UUID.parse(value);
		} catch (Exception ex) {
		}

		return result;
	}

	override public Integer hashCode() {
		return this.qs.hashCode();
	}

	public Boolean equals(Object obj) {
		if (this === obj) return true;

		if (obj == null || !(obj instanceof QueryString)) return false;

		return this.qs.equals(((QueryString)obj).qs);
	}

	override public String toString() {
		String result = '';
		Boolean isFirst = true;

		for (String key : Keys) {
			String value = get(key);
			if (String.isBlank(value)) value = '';
			if (isFirst) {
				result += StringUtils.encode(key)
					+ '=' + StringUtils.encode(value);
				isFirst = false;
			} else
				result += '&' + StringUtils.encode(key)
					+ '=' + StringUtils.encode(value);
		}

		return result;
	}

	public void copyTo(final Map<String, String> params) {
		if (params != null) params.putAll(this.qs);
	}
}
