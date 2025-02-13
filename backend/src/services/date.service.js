const moment = require('moment');

class DateService {
  constructor() {
    moment.locale('fr');
  }

  /**
   * Format a date to a specific format
   * @param {Date|string} date - The date to format
   * @param {string} format - The format to use (default: 'YYYY-MM-DD')
   * @returns {string} The formatted date
   */
  formatDate(date, format = 'YYYY-MM-DD') {
    return moment(date).format(format);
  }

  /**
   * Get the difference between two dates
   * @param {Date|string} date1 - First date
   * @param {Date|string} date2 - Second date
   * @param {string} unit - The unit to return (years, months, weeks, days, hours, minutes)
   * @returns {number} The difference between the two dates in the specified unit
   */
  getDifference(date1, date2, unit = 'days') {
    return moment(date1).diff(moment(date2), unit);
  }

  /**
   * Add a duration to a date
   * @param {Date|string} date - The date to add to
   * @param {number} amount - The amount to add
   * @param {string} unit - The unit to add (years, months, weeks, days, hours, minutes)
   * @returns {Date} The new date
   */
  addToDate(date, amount, unit = 'days') {
    return moment(date).add(amount, unit).toDate();
  }

  /**
   * Subtract a duration from a date
   * @param {Date|string} date - The date to subtract from
   * @param {number} amount - The amount to subtract
   * @param {string} unit - The unit to subtract (years, months, weeks, days, hours, minutes)
   * @returns {Date} The new date
   */
  subtractFromDate(date, amount, unit = 'days') {
    return moment(date).subtract(amount, unit).toDate();
  }

  /**
   * Check if a date is between two other dates
   * @param {Date|string} date - The date to check
   * @param {Date|string} start - The start date
   * @param {Date|string} end - The end date
   * @returns {boolean} True if the date is between start and end
   */
  isBetween(date, start, end) {
    return moment(date).isBetween(start, end, 'day', '[]');
  }

  /**
   * Check if a date is valid
   * @param {Date|string} date - The date to check
   * @returns {boolean} True if the date is valid
   */
  isValidDate(date) {
    return moment(date).isValid();
  }

  /**
   * Get the start of a unit of time
   * @param {Date|string} date - The reference date
   * @param {string} unit - The unit (year, month, week, day)
   * @returns {Date} The start of the unit
   */
  startOf(date, unit = 'day') {
    return moment(date).startOf(unit).toDate();
  }

  /**
   * Get the end of a unit of time
   * @param {Date|string} date - The reference date
   * @param {string} unit - The unit (year, month, week, day)
   * @returns {Date} The end of the unit
   */
  endOf(date, unit = 'day') {
    return moment(date).endOf(unit).toDate();
  }

  /**
   * Get a relative time string (e.g., "il y a 2 jours")
   * @param {Date|string} date - The date to get relative time for
   * @returns {string} The relative time string
   */
  getRelativeTime(date) {
    return moment(date).fromNow();
  }

  /**
   * Check if a date is after another date
   * @param {Date|string} date1 - First date
   * @param {Date|string} date2 - Second date
   * @returns {boolean} True if date1 is after date2
   */
  isAfter(date1, date2) {
    return moment(date1).isAfter(date2);
  }

  /**
   * Check if a date is before another date
   * @param {Date|string} date1 - First date
   * @param {Date|string} date2 - Second date
   * @returns {boolean} True if date1 is before date2
   */
  isBefore(date1, date2) {
    return moment(date1).isBefore(date2);
  }

  /**
   * Get the number of days in a month
   * @param {Date|string} date - The reference date
   * @returns {number} The number of days in the month
   */
  getDaysInMonth(date) {
    return moment(date).daysInMonth();
  }
}

module.exports = new DateService();
