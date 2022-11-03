#ifndef CONVERSION_FUNCTIONS_COMMON_H
#define CONVERSION_FUNCTIONS_COMMON_H

#include <cstring>
#include <iomanip>
#include <iterator>
#include <string>
#include <sstream>
#include <vector>

using std::pair;
using std::string;
using std::vector;

/**
 * Convert a string to a C++ equivalent bigint type.
 * 
 * @param value The string to convert.
 * @return The bigint value converted from the string.
*/
long long int stringToBigInt(const string &value);

/**
 * Convert a vector of strings to vector of C++ equivalent bigint types.
 * 
 * @param data The vector of strings to convert.
 * @param The vector of bigint values converted from the vector of strings.
 * @return The vector of bigint values converted from the vector of strings.
*/
vector<long long int> getExpectedResults_BigInt(const vector<string> &data);

/**
 * Convert integer string into hex string with proper padding
 *
 * @param inserted_int string of an integer to be converted to hex
 * @param table_size size of the 
 * @return string of the integer in hexadecimal values
 */ 
std::string getHexRepresentation(string inserted_int, size_t table_size = -1);

/**
 * Convert a vector of strings to vector of binary strings.
 * 
 * @param data The vector of strings to convert.
 * @param table_size The size of the table. 
 * @return The vector of binary values converted from the vector of strings.
*/
vector<string> getExpectedResults_Binary(const vector<string> &data, size_t table_size);

/**
 * Convert a vector of strings to vector of varbinary strings.
 * 
 * @param data The vector of strings to convert.
 * @param table_size The size of the table. 
 * @return The vector of varbinary values converted from the vector of strings.
*/
vector<string> getExpectedResults_VarBinary(const vector<string> &data);

/**
 * Convert a string to a C++ equivalent bit type. Any non-zero values passed into this function are converted to 1.
 * 
 * @param value The string to convert.
 * @return The bit value converted from the string.
*/
unsigned char stringToBit(const string &value);

/**
 * Convert a vector of strings to vector of C++ equivalent bit types. Any non-zero values passed in the vector will be converted to 1.
 * 
 * @param data The vector of strings to convert.
 * @param The vector of bigint values converted from the vector of strings.
 * @return The vector of bit values converted from the vector of strings.
*/
vector<unsigned char> getExpectedResults_Bit(const vector<string> &data);

/**
 * Convert a string to a hex string.
 * 
 * @param value The string to convert.
 * @return The hex string.
*/
string stringToHex(string input);

/**
 * Convert a vector of strings to vector of hex strings.
 * 
 * @param data The vector of strings to convert.
 * @return The vector of hex strings converted from the vector of strings.
*/
vector<string> getExpectedResults_Bytea(const vector<string> &data);

/**
 * Convert a string to a double.
 * 
 * @param value The string to convert.
 * @return The double value converted from the string.
*/
double stringToDouble(const string &value);

/**
 * Convert a vector of strings to vector of doubles.
 * 
 * @param data The vector of strings to convert.
 * @return The vector of doubles converted from the vector of strings.
*/
vector<double> getExpectedResults_Double(const vector<string> &data);

/**
 * Convert a string to an int.
 * 
 * @param value The string to convert.
 * @return The int value converted from the string.
*/
int stringToInt(const string &value);

/**
 * Convert a vector of strings to vector of ints.
 * 
 * @param data The vector of strings to convert.
 * @return The vector of ints converted from the vector of strings.
*/
vector<int> getExpectedResults_Int(const vector<string> &data);

/**
 * Convert a string to an short int.
 * 
 * @param value The string to convert.
 * @return The short int value converted from the string.
*/
short int stringToShortInt(const string &value);

/**
 * Convert a vector of strings to vector of short ints.
 * 
 * @param data The vector of strings to convert.
 * @return The vector of short ints converted from the vector of strings.
*/
vector<short int> getExpectedResults_ShortInt(const vector<string> &data);

/**
 * Convert a string to a float.
 * 
 * @param value The string to convert.
 * @return The float value converted from the string.
*/
float stringToFloat(const string &value);

/**
 * Convert a vector of strings to vector of floats.
 * 
 * @param data The vector of strings to convert.
 * @return The vector of floats converted from the vector of strings.
*/
vector<float> getExpectedResults_Float(const vector<string> &data);

/**
 * Convert a string to time.
 * 
 * @param value The string to convert.
 * @param timeBytesExpected The time in bytes expected.
 * @return The time value converted from the string.
*/
string stringToTime(const string &input, const int timeBytesExpected);

/**
 * Convert a vector of strings to vector of time.
 * 
 * @param data The vector of strings to convert.
 * @param timeBytesExpected The time in bytes expected.
 * @return The vector of floats converted from the vector of strings.
*/
vector<string> getExpectedResults_Time(const vector<string> &input, const int timeBytesExpected);

/**
 * Converts a hex value (withotu 0x) to it's associated integer string.
 * 
 * @param input The hex, as a string, to convert.
 * @return The associated integer as a string of the hex.
*/
string hexToIntStr(const string &input);

/** 
 * Left pads (adds spaces on the right side) the input string until a length of table_size
 * 
 * @param input The String to be padded.
 * @param table_size The desired length.
 */
string padString(string input, size_t table_size);

/**
 * Convert a vector of strings to expected character results.
 * 
 * @param The vector of strings to convert.
 * @param table_size The size of the table.
*/
vector<string> getExpectedResults_Char(const vector<string> &input, size_t table_size);

#endif
