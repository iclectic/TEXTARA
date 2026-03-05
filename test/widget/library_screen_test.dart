import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/presentation/widgets/library/book_grid_tile.dart';
import 'package:textara/presentation/widgets/library/book_list_tile.dart';
import 'package:textara/presentation/widgets/library/library_empty_state.dart';

void main() {
  group('LibraryEmptyState widget', () {
    testWidgets('displays import button and empty message',
        (WidgetTester tester) async {
      bool importTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryEmptyState(
              onImport: () => importTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Import books'), findsOneWidget);

      await tester.tap(find.text('Import books'));
      expect(importTapped, true);
    });
  });

  group('BookGridTile widget', () {
    testWidgets('displays book title and author', (WidgetTester tester) async {
      final book = Book(
        id: 'grid-test',
        title: 'Great Expectations',
        author: 'Charles Dickens',
        filePath: '/test.epub',
        format: BookFormat.epub,
        dateAdded: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: BookGridTile(
                book: book,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Great Expectations'), findsAtLeastNWidgets(1));
      expect(find.text('Charles Dickens'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows favourite indicator when book is favourite',
        (WidgetTester tester) async {
      final book = Book(
        id: 'fav-test',
        title: 'Favourite Book',
        author: 'Author',
        filePath: '/test.epub',
        format: BookFormat.epub,
        dateAdded: DateTime.now(),
        isFavourite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: BookGridTile(
                book: book,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('does not show favourite indicator for non-favourite',
        (WidgetTester tester) async {
      final book = Book(
        id: 'no-fav-test',
        title: 'Normal Book',
        author: 'Author',
        filePath: '/test.epub',
        format: BookFormat.epub,
        dateAdded: DateTime.now(),
        isFavourite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: BookGridTile(
                book: book,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });
  });

  group('BookListTile widget', () {
    testWidgets('displays book details and status',
        (WidgetTester tester) async {
      final book = Book(
        id: 'list-test',
        title: 'Oliver Twist',
        author: 'Charles Dickens',
        filePath: '/test.epub',
        format: BookFormat.epub,
        readingStatus: ReadingStatus.reading,
        readingProgress: 0.65,
        dateAdded: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookListTile(
              book: book,
              onTap: () {},
              onFavourite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Oliver Twist'), findsOneWidget);
      expect(find.text('Charles Dickens'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('EPUB'), findsOneWidget);
    });

    testWidgets('favourite button toggles correctly',
        (WidgetTester tester) async {
      bool favouriteTapped = false;
      final book = Book(
        id: 'fav-toggle',
        title: 'Test Book',
        author: 'Author',
        filePath: '/test.epub',
        format: BookFormat.epub,
        dateAdded: DateTime.now(),
        isFavourite: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookListTile(
              book: book,
              onTap: () {},
              onFavourite: () => favouriteTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favouriteTapped, true);
    });

    testWidgets('shows PDF format label for PDF books',
        (WidgetTester tester) async {
      final book = Book(
        id: 'pdf-label',
        title: 'PDF Book',
        author: 'Author',
        filePath: '/test.pdf',
        format: BookFormat.pdf,
        dateAdded: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookListTile(
              book: book,
              onTap: () {},
              onFavourite: () {},
            ),
          ),
        ),
      );

      expect(find.text('PDF'), findsOneWidget);
    });
  });
}
