import React from 'react';
import { Menu } from '@headlessui/react';
import { format, subMonths, startOfMonth } from 'date-fns';
import { fr } from 'date-fns/locale';

const ChartFilters = ({ onFilterChange, currentFilter }) => {
  const periods = [
    { name: '7 derniers jours', value: '7d' },
    { name: '30 derniers jours', value: '30d' },
    { name: '3 derniers mois', value: '3m' },
    { name: '6 derniers mois', value: '6m' },
    { name: '1 an', value: '1y' },
  ];

  const generateDateRange = (period) => {
    const end = new Date();
    let start;

    switch (period) {
      case '7d':
        start = subMonths(end, 7);
        break;
      case '30d':
        start = subMonths(end, 1);
        break;
      case '3m':
        start = subMonths(end, 3);
        break;
      case '6m':
        start = subMonths(end, 6);
        break;
      case '1y':
        start = subMonths(end, 12);
        break;
      default:
        start = subMonths(end, 1);
    }

    return {
      start: startOfMonth(start),
      end: end,
    };
  };

  const handlePeriodChange = (period) => {
    const dateRange = generateDateRange(period);
    onFilterChange({
      period,
      dateRange,
    });
  };

  return (
    <div className="flex items-center space-x-4 mb-4">
      <Menu as="div" className="relative">
        <Menu.Button className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500">
          {periods.find(p => p.value === currentFilter.period)?.name || 'Période'}
        </Menu.Button>

        <Menu.Items className="absolute z-10 mt-2 w-56 rounded-md shadow-lg bg-white dark:bg-gray-800 ring-1 ring-black ring-opacity-5 focus:outline-none">
          <div className="py-1">
            {periods.map((period) => (
              <Menu.Item key={period.value}>
                {({ active }) => (
                  <button
                    onClick={() => handlePeriodChange(period.value)}
                    className={`${
                      active
                        ? 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white'
                        : 'text-gray-700 dark:text-gray-200'
                    } group flex items-center w-full px-4 py-2 text-sm`}
                  >
                    {period.name}
                  </button>
                )}
              </Menu.Item>
            ))}
          </div>
        </Menu.Items>
      </Menu>

      <div className="text-sm text-gray-500 dark:text-gray-400">
        {format(currentFilter.dateRange.start, 'dd MMM yyyy', { locale: fr })} -{' '}
        {format(currentFilter.dateRange.end, 'dd MMM yyyy', { locale: fr })}
      </div>
    </div>
  );
};

export default ChartFilters;
