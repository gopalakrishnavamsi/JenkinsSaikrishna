public class Collection {

	public static Boolean isEmpty(final List<Object> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isNotEmpty(final List<Object> o) {
		return o != null && !o.isEmpty();
	}

	public static Boolean isEmpty(final Set<String> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isNotEmpty(final Set<String> o) {
		return o != null && !o.isEmpty();
	}

	public static Boolean isEmpty(final Set<Id> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isNotEmpty(final Set<Id> o) {
		return o != null && !o.isEmpty();
	}

	public static Boolean isEmpty(final Set<UUID> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isNotEmpty(final Set<UUID> o) {
		return o != null && !o.isEmpty();
	}

	public static Boolean isEmpty(final Map<String, Object> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isEmpty(final Map<Id, Object> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isEmpty(final Map<UUID, Object> o) {
		return o == null || o.isEmpty();
	}

	public static Boolean isNotEmpty(final Map<String, Object> o) {
		return o != null && !o.isEmpty();
	}

	public static Boolean isNotEmpty(final Map<Id, Object> o) {
		return o != null && !o.isEmpty();
	}

	public static Boolean isNotEmpty(final Map<UUID, Object> o) {
		return o != null && !o.isEmpty();
	}

	public static String mkString(final List<Object> c, final String separator) {
		String result = '';
		if (isNotEmpty(c)) {
			String sep = separator != null ? separator : '';
			Boolean isNotFirst = false;
			for (Object o : c) {
				if (isNotFirst) {
					result += sep + String.valueOf(o);
				} else {
					result += String.valueOf(o);
					isNotFirst = true;
				}
			}
		}
		return result;
	}

	// I wish we could use co/contravariant type arguments in apex...
	public static Boolean containsKey(final Map<String, Object> c, final String key) {
		return isNotEmpty(c) && c.containsKey(key);
	}

	public static Set<String> keys(final Map<String, Object> c) {
		return c == null ? new Set<String>() : c.keySet();
	}

	// Ugh, these should be standard Set methods...
	public static Set<Id> union(final Set<Id> left, final Set<Id> right) {
		Set<Id> result = new Set<Id>();
		if (left != null) result.addAll(left);
		if (right != null) result.addAll(right);
		return result;
	}

	public static Set<Id> difference(final Set<Id> left, final Set<Id> right) {
		Set<Id> result = new Set<Id>();
		if (left != null) {
			if (right == null) {
				result.addAll(left);
			} else {
				for (Id i : left) {
					if (!right.contains(i)) {
						result.add(i);
					}
				}
			}
		}
		return result;
	}

	public static Set<UUID> difference(final Set<UUID> left, final Set<UUID> right) {
		Set<UUID> result = new Set<UUID>();
		if (left != null) {
			if (right == null) {
				result.addAll(left);
			} else {
				for (UUID u : left) {
					if (!right.contains(u)) {
						result.add(u);
					}
				}
			}
		}
		return result;
	}

	public static Set<String> difference(final Set<String> left, final Set<String> right) {
		Set<String> result = new Set<String>();
		if (left != null) {
			if (right == null) {
				result.addAll(left);
			} else {
				for (String s : left) {
					if (!right.contains(s)) {
						result.add(s);
					}
				}
			}
		}
		return result;
	}

	public static Set<Id> intersection(final Set<Id> left, final Set<Id> right) {
		Set<Id> result = new Set<Id>();
		if (left != null && right != null) {
			for (Id i : left) {
				if (right.contains(i)) {
					result.add(i);
				}
			}
			for (Id i : right) {
				if (left.contains(i)) {
					result.add(i);
				}
			}
		}
		return result;
	}

	public static Set<String> intersection(final Set<String> left, final Set<String> right) {
		Set<String> result = new Set<String>();
		if (left != null && right != null) {
			for (String s : left) {
				if (right.contains(s)) {
					result.add(s);
				}
			}
			for (String s : right) {
				if (left.contains(s)) {
					result.add(s);
				}
			}
		}
		return result;
	}

	public static Object head(final List<Object> l) {
		if (Collection.isEmpty(l)) return null;

		return l[0];
	}

	public static Id head(final Set<Id> s) {
		if (Collection.isEmpty(s)) return null;

		return (Id)s.iterator().next();
	}

	public static Object last(final List<Object> l) {
		Integer size = size(l);
		if (size <= 0) return null;

		return l[size - 1];
	}

	public static Object get(final List<Object> l, final Integer i) {
		Integer size = size(l);
		if (size <= 0 || i < 0 || i >= size) return null;

		return l[i];
	}

	public static Integer size(final List<Object> l) {
		if (l == null) return 0;

		return l.size();
	}

	public static List<Object> slice(final List<Object> l, final Integer s) {
		List<Object> result = new List<Object>();
		for (Integer i = s >= 0 ? s : 0; i < size(l); i++) {
			result.add(l[i]);
		}
		return result;
	}

	public static Integer indexOf(final List<Object> l, final Object o) {
		return isEmpty(l) ? -1 : l.indexOf(o);
	}

	public static List<List<String>> chunk(final List<String> l, final Integer s) {
		List<List<String>> result = new List<List<String>>();
		List<String> tempList = new List<String>();
		if (l <> null && l.size() > 0) {
			for (Integer i = 0; i < l.size(); i++) {
				tempList.add(l[i]);
				if (tempList.size() >= s) {
					result.add(tempList);
					tempList = new List<String>();
				}
			}
			if (tempList.size() > 0) {
				result.add(tempList);
			}
		}
		return result;
	}
}
