@IsTest(IsParallel = true)
private class CollectionTest {

	@IsTest
	static void test_isEmpty() {
		System.assert(Collection.isEmpty((List<Object>)null));
		System.assert(Collection.isEmpty((Set<String>)null));
		System.assert(Collection.isEmpty((Set<Id>)null));
		System.assert(Collection.isEmpty((Map<String, Object>)null));
		System.assert(Collection.isEmpty(new List<Object>()));
		System.assert(Collection.isEmpty(new Set<String>()));
		System.assert(Collection.isEmpty(new Set<Id>()));
		System.assert(Collection.isEmpty(new Map<String, Object>()));
		System.assert(!Collection.isEmpty(new List<Object> { 1 }));
		System.assert(!Collection.isEmpty(new Set<String> { '1' }));
		System.assert(!Collection.isEmpty(new Set<Id> { UserInfo.getUserId() }));
		System.assert(!Collection.isEmpty(new Map<String, Object> { '1' => 1 }));
		System.assert(Collection.isEmpty((Set<UUID>)null));
		System.assert(Collection.isEmpty(new Set<UUID>()));
		System.assert(!Collection.isEmpty(new Set<UUID> { UUID.randomUUID() }));
	}

	@IsTest
	static void test_isNotEmpty() {
		System.assert(!Collection.isNotEmpty((List<Object>)null));
		System.assert(!Collection.isNotEmpty((Set<String>)null));
		System.assert(!Collection.isNotEmpty((Set<Id>)null));
		System.assert(!Collection.isNotEmpty((Map<String, Object>)null));
		System.assert(!Collection.isNotEmpty(new List<Object>()));
		System.assert(!Collection.isNotEmpty(new Set<String>()));
		System.assert(!Collection.isNotEmpty(new Set<Id>()));
		System.assert(!Collection.isNotEmpty(new Map<String, Object>()));
		System.assert(Collection.isNotEmpty(new List<Object> { 1 }));
		System.assert(Collection.isNotEmpty(new Set<String> { '1' }));
		System.assert(Collection.isNotEmpty(new Set<Id> { UserInfo.getUserId() }));
		System.assert(Collection.isNotEmpty(new Map<String, Object> { '1' => 1 }));
		System.assert(!Collection.isNotEmpty((Set<UUID>)null));
		System.assert(!Collection.isNotEmpty(new Set<UUID>()));
		System.assert(Collection.isNotEmpty(new Set<UUID> { UUID.randomUUID() }));
	}

	@IsTest
	static void test_mkString() {
		System.assertEquals('', Collection.mkString(null, ', '));
		System.assertEquals('', Collection.mkString(new List<Object>(), ', '));
		System.assertEquals('1', Collection.mkString(new List<Object> { 1 }, ', '));
		System.assertEquals('1, 2, null', Collection.mkString(new List<Object> { 1, 2, null }, ', '));
	}

	@IsTest
	static void test_containsKey() {
		System.assert(!Collection.containsKey(null, 'key'));
		System.assert(!Collection.containsKey(new Map<String, Object>(), 'key'));
		System.assert(!Collection.containsKey(new Map<String, Object> { '1' => 1 }, 'key'));
		System.assert(Collection.containsKey(new Map<String, Object> { '1' => 1, 'key' => 2 }, 'key'));
		System.assert(!Collection.containsKey(new Map<String, Object> { '1' => 1, 'key' => 2 }, null));
		System.assert(!Collection.containsKey(new Map<String, Object> { '1' => 1, 'key' => 2 }, ''));
		System.assert(!Collection.containsKey(new Map<String, Object> { '1' => 1, 'key' => 2 }, ' \t'));
	}

	@IsTest
	static void test_keys() {
		System.assertNotEquals(null, Collection.keys(null));
		System.assertEquals(new Set<String>(), Collection.keys(null));
		System.assertEquals(new Set<String>(), Collection.keys(new Map<String, Object>()));
		System.assertEquals(new Set<String> { 'a', 'b' }, Collection.keys(new Map<String, Integer> {
			'a' => 1,
			'b' => 2
		}));
	}

	@IsTest
	static void test_union() {
		Set<Id> s1 = new Set<Id> { '00541000002aMAA', '00541000002aMAB' };
		Set<Id> s2 = new Set<Id> { '00541000002aMAA', '00541000002aMAC' };

		System.assertEquals(new Set<Id>(), Collection.union(null, null));
		System.assertEquals(s1, Collection.union(s1, null));
		System.assertEquals(s2, Collection.union(null, s2));
		System.assertEquals(new Set<Id> { '00541000002aMAA', '00541000002aMAB', '00541000002aMAC' }, Collection.union(s1, s2));
	}

	@IsTest
	static void test_difference_Id() {
		Set<Id> s1 = new Set<Id> { '00541000002aMAA', '00541000002aMAB' };
		Set<Id> s2 = new Set<Id> { '00541000002aMAA', '00541000002aMAC' };

		System.assertEquals(new Set<Id>(), Collection.difference((Set<Id>)null, (Set<Id>)null));
		System.assertEquals(new Set<Id>(), Collection.difference(null, s2));
		System.assertEquals(s1, Collection.difference(s1, null));
		System.assertEquals(new Set<Id> { '00541000002aMAB' }, Collection.difference(s1, s2));
		System.assertEquals(new Set<Id> { '00541000002aMAC' }, Collection.difference(s2, s1));
	}

	@IsTest
	static void test_difference_UUID() {
		UUID u1 = UUID.randomUUID();
		UUID u2 = UUID.randomUUID();
		UUID u3 = UUID.randomUUID();
		Set<UUID> s1 = new Set<UUID> { u1, u2 };
		Set<UUID> s2 = new Set<UUID> { u1, u3 };

		System.assertEquals(new Set<UUID>(), Collection.difference((Set<UUID>)null, (Set<UUID>)null));
		System.assertEquals(new Set<UUID>(), Collection.difference((Set<UUID>)null, s2));
		System.assertEquals(s1, Collection.difference(s1, (Set<UUID>)null));
		System.assertEquals(new Set<UUID> { u2 }, Collection.difference(s1, s2));
		System.assertEquals(new Set<UUID> { u3 }, Collection.difference(s2, s1));
	}

	@IsTest
	static void test_intersection_Id() {
		Set<Id> s1 = new Set<Id> { '00541000002aMAA', '00541000002aMAB' };
		Set<Id> s2 = new Set<Id> { '00541000002aMAA', '00541000002aMAC' };

		System.assertEquals(new Set<Id>(), Collection.intersection((Set<Id>)null, (Set<Id>)null));
		System.assertEquals(new Set<Id>(), Collection.intersection(s1, null));
		System.assertEquals(new Set<Id>(), Collection.intersection(null, s2));
		System.assertEquals(new Set<Id> { '00541000002aMAA' }, Collection.intersection(s1, s2));
	}

	@IsTest
	static void test_intersection_String() {
		Set<String> s1 = new Set<String> { 'string1', 'string2' };
		Set<String> s2 = new Set<String> { 'string1', 'string3' };

		System.assertEquals(new Set<String>(), Collection.intersection((Set<String>)null, (Set<String>)null));
		System.assertEquals(new Set<String>(), Collection.intersection(s1, null));
		System.assertEquals(new Set<String>(), Collection.intersection(null, s2));
		System.assertEquals(new Set<String> { 'string1' }, Collection.intersection(s1, s2));
	}

	@IsTest
	static void test_head() {
		System.assertEquals(null, Collection.head((List<Object>)null));
		System.assertEquals(null, Collection.head((Set<Id>)null));
		System.assertEquals(null, Collection.head(new List<String>()));
		System.assertEquals(null, Collection.head(new Set<Id>()));
		System.assertEquals(1, Collection.head(new List<Integer> { 1 }));
		System.assertEquals(1, Collection.head(new List<Integer> { 1, 2, 3 }));
		System.assertEquals('00541000002aMAA', Collection.head(new Set<Id> { '00541000002aMAA' }));
		System.assertEquals('00541000002aMAA', Collection.head(new Set<Id> { '00541000002aMAA', '00541000002aMAB' }));
	}

	@IsTest
	static void test_last() {
		System.assertEquals(null, Collection.last(null));
		System.assertEquals(null, Collection.last(new List<Object>()));
		System.assertEquals(1, Collection.last(new List<Integer> { 1 }));
		System.assertEquals(3, Collection.last(new List<Integer> { 1, 2, 3 }));
	}

	@IsTest
	static void test_get() {
		System.assertEquals(null, Collection.get(null, 0));
		System.assertEquals(null, Collection.get(new List<Object>(), 0));
		System.assertEquals(1, Collection.get(new List<Integer> { 1 }, 0));
		System.assertEquals(3, Collection.get(new List<Integer> { 1, 2, 3 }, 2));
		System.assertEquals(null, Collection.get(new List<Integer> { 1, 2, 3 }, -1));
		System.assertEquals(null, Collection.get(new List<Integer> { 1, 2, 3 }, 3));
	}

	@IsTest
	static void test_size() {
		System.assertEquals(0, Collection.size(null));
		System.assertEquals(0, Collection.size(new List<Object>()));
		System.assertEquals(2, Collection.size(new List<Integer> { 1, 2 }));
	}

	@IsTest
	static void test_slice() {
		System.assertEquals(new List<Integer>(), Collection.slice((List<Integer>)null, 2));
		System.assertEquals(new List<Integer>(), Collection.slice(new List<Integer>(), 2));
		List<String> l = new List<String> { '0', '1', '2' };
		System.assertEquals(new List<String> { '0', '1', '2' }, Collection.slice(l, -1));
		System.assertEquals(new List<String> { '0', '1', '2' }, Collection.slice(l, 0));
		System.assertEquals(new List<String> { '1', '2' }, Collection.slice(l, 1));
		System.assertEquals(new List<String>(), Collection.slice(l, 3));

	}

	@IsTest
	static void test_indexOf() {
		System.assertEquals(-1, Collection.indexOf(null, null));
		System.assertEquals(-1, Collection.indexOf(new List<Object>(), null));
		System.assertEquals(-1, Collection.indexOf(new List<Object>(), 'something'));
		System.assertEquals(-1, Collection.indexOf(new List<Integer> { 1, 2, 3 }, 'four'));
		System.assertEquals(1, Collection.indexOf(new List<Integer> { 1, 2, 3 }, 2));

	}
}
