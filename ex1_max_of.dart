// Exercise 1: Generic Function with Constraints
// Returns the maximum element from a list.
// T must implement Comparable<T> — enforced at compile time.

T? maxOf<T extends Comparable<T>>(List<T> list) {
  if (list.isEmpty) return null;
  return list.fold(
    list[0],
    (acc, item) => item.compareTo(acc!) > 0 ? item : acc,
  );
}

void main() {
  // Type T is inferred automatically from the list elements
  print(maxOf([3, 7, 2, 9]));             // 9
  print(maxOf(['apple', 'banana', 'kiwi'])); // kiwi
  print(maxOf(<int>[]));                  // null
}
