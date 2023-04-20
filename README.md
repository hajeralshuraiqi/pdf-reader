# pdfreader

pdfreader is a Flutter iOS app that provides users with a seamless way to upload, store, search, and manage their PDF files using Firebase. With its intuitive interface and easy-to-use features,
this app is designed to enhance productivity and improve user experience.

The app consists of two main pages: Home and Search.

Home: On the Home page, users can effortlessly upload PDF files to a Firebase collection. The app securely stores the uploaded files, allowing users to access and manage their documents anytime, anywhere.

Search: The Search page is designed to help users quickly find relevant information within their stored PDF files. By entering a specific keyword or phrase, the app searches through the database and displays a list of PDFs containing the searched term. Along with the list of PDFs, the app also shows the sentences where the searched term is found, providing users with better context and understanding. Additionally, users can easily delete any PDF file from Firebase directly through the app.

With the PDF Search & Storage App, users can efficiently manage their documents and effortlessly search for relevant information, making it an essential tool for students, researchers, and professionals alike.

This README will guide you through the process of setting up and running the project on your local machine.

## Prerequisites

To run this project, you need to have the following software installed on your machine:

1. [Flutter](https://flutter.dev/docs/get-started/install): Follow the official Flutter documentation to install the Flutter SDK.
2. [Xcode](https://developer.apple.com/xcode/): Install Xcode, the official development environment for iOS apps, from the Mac App Store.

Make sure to configure your environment according to the [official Flutter documentation for iOS](https://flutter.dev/docs/get-started/install/macos#install-xcode).

## Getting Started

1. Clone the repository to your local machine:

   git clone https://github.com/hajeralshuraiqi/pdf-reader

2. I gave you an access to firebase project with your email(info@rihal.om), please accept the invitation that have been sent to your email.


2. Change to the project directory:

   cd pdfreader

3. Install the necessary dependencies:

   flutter pub get

4. Open the project in Xcode:

   open ios/Runner.xcworkspace

5. Alternatively, you can run the app from the command line:
   1. cd pdfreader
   2. flutter run







