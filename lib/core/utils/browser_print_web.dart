// ignore: deprecated_member_use
import 'dart:html' as html;

bool get canPrintBrowserPage => true;

void printBrowserPage() => html.window.print();

void printA4BrowserPage() {
  const styleId = 'farm-estates-a4-print-style';
  var style = html.document.getElementById(styleId) as html.StyleElement?;
  if (style == null) {
    style = html.StyleElement()..id = styleId;
    html.document.head?.append(style);
  }
  style.text = '''
    @page {
      size: A4 portrait;
      margin: 12mm;
    }
    @media print {
      html, body {
        width: 100% !important;
        min-height: 273mm !important;
        margin: 0 !important;
        padding: 0 !important;
        background: #ffffff !important;
      }
      flutter-view {
        width: 100% !important;
        min-height: 273mm !important;
        background: #ffffff !important;
      }
    }
  ''';
  html.window.print();
}
