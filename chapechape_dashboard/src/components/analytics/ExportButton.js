import React from 'react';
import { Menu } from '@headlessui/react';
import { ArrowDownTrayIcon } from '@heroicons/react/24/outline';
import * as XLSX from 'xlsx';
import { PDFDownloadLink, Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';

const styles = StyleSheet.create({
  page: {
    flexDirection: 'column',
    backgroundColor: '#FFFFFF',
    padding: 30,
  },
  section: {
    margin: 10,
    padding: 10,
  },
  title: {
    fontSize: 24,
    marginBottom: 20,
  },
  table: {
    display: 'table',
    width: '100%',
    borderStyle: 'solid',
    borderWidth: 1,
    borderColor: '#000',
  },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#000',
  },
  tableCell: {
    padding: 5,
    flex: 1,
  },
});

const PDFDocument = ({ data }) => (
  <Document>
    <Page size="A4" style={styles.page}>
      <View style={styles.section}>
        <Text style={styles.title}>Rapport ChapeChape</Text>
        {data.map((item, index) => (
          <View key={index} style={styles.tableRow}>
            <Text style={styles.tableCell}>{item.label}</Text>
            <Text style={styles.tableCell}>{item.value}</Text>
          </View>
        ))}
      </View>
    </Page>
  </Document>
);

const ExportButton = ({ data, filename = 'export' }) => {
  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Data');
    XLSX.writeFile(wb, `${filename}.xlsx`);
  };

  return (
    <Menu as="div" className="relative inline-block text-left">
      <Menu.Button className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700">
        <ArrowDownTrayIcon className="h-5 w-5 mr-2" />
        Exporter
      </Menu.Button>

      <Menu.Items className="absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white dark:bg-gray-800 ring-1 ring-black ring-opacity-5 focus:outline-none z-10">
        <div className="py-1">
          <Menu.Item>
            {({ active }) => (
              <button
                onClick={exportToExcel}
                className={`${
                  active
                    ? 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white'
                    : 'text-gray-700 dark:text-gray-200'
                } group flex items-center w-full px-4 py-2 text-sm`}
              >
                Exporter en Excel
              </button>
            )}
          </Menu.Item>
          <Menu.Item>
            {({ active }) => (
              <PDFDownloadLink
                document={<PDFDocument data={data} />}
                fileName={`${filename}.pdf`}
                className={`${
                  active
                    ? 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white'
                    : 'text-gray-700 dark:text-gray-200'
                } group flex items-center w-full px-4 py-2 text-sm`}
              >
                Exporter en PDF
              </PDFDownloadLink>
            )}
          </Menu.Item>
        </div>
      </Menu.Items>
    </Menu>
  );
};

export default ExportButton;
