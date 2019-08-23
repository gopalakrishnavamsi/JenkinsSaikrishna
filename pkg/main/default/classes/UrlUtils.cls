public class UrlUtils {

	public static Url canonicalizeBaseUrl(final Url url) {
		if (url == null) return null;

		String path = url.getPath().toLowerCase();
		return new Url('https://' + url.getAuthority().toLowerCase() + (path.endsWith('/') ? path : path + '/'));
	}
}
