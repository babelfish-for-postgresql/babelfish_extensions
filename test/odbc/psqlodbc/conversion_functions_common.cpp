#include "conversion_functions_common.h"

long long int stringToBigInt(const string &value) {
  if (value == "NULL") {
    // Return a dummy value of zero.
    return 0;
  }
  return strtoll(value.c_str(), NULL, 10);
}

vector<long long int> getExpectedResults_BigInt(const vector<string> &data) {
  vector<long long int> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(stringToBigInt(data[i]));
  }

  return expectedResults;
}

std::string getHexRepresentation(string inserted_int, size_t table_size) {
  if (inserted_int == "NULL") {
    return "NULL";
  }

  std::stringstream stream;
  stream << std::hex << strtoul(inserted_int.c_str(), nullptr, 10);
  string expected_hex = stream.str();

  size_t expected_length = expected_hex.length();
  if (table_size == -1 || table_size >= 8) {
    if (((expected_length + 7) & (-8)) - expected_length == 0) {
      // Pad with extra 8 characters
      expected_length += 8;
    }

    // Round to nearest multiple of 8
    expected_length = ((expected_length + 7) & (-8));
  }
  else {
    expected_length = table_size * 2;
  }

  // Padding extra one `0` if not in multiple of 2s
  expected_length = expected_length % 2 == 0 ? expected_length : expected_length + 1;

  // Prepend string with '0x'
  int extra_padding = expected_length - expected_hex.length();
  if (extra_padding < 0) {
    return "0x" + expected_hex.substr(expected_hex.length() - expected_length, expected_length);
  } 
  else if (extra_padding > 0){
    return "0x" + string(extra_padding, '0') + expected_hex;
  }
  return "0x" + expected_hex;
}

vector<string> getExpectedResults_Binary(const vector<string> &data, size_t table_size) {
  vector<string> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(getHexRepresentation(data[i], table_size));
  }

  return expectedResults;
}

vector<string> getExpectedResults_VarBinary(const vector<string> &data) {
  vector<string> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(getHexRepresentation(data[i]));
  }

  return expectedResults;
}

// Helper to convert string into a bit
// Any non-zero values are converted to 1
unsigned char stringToBit(const string &value) {
  if (value == "NULL") {
    // Return a dummy value of zero.
    return 0;
  }
  return strtol(value.c_str(), NULL, 10) != 0 ? 1 : 0;
}

vector<unsigned char> getExpectedResults_Bit(const vector<string> &data) {
  vector<unsigned char> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(stringToBit(data[i]));
  }

  return expectedResults;
}

string stringToHex(string input) {
    std::ostringstream result;
    result << std::setw(2) << std::setfill('0') << std::hex << std::uppercase;
    string::iterator start = input.begin();
    if (input.find('\\') != string::npos) {
      start = std::next(start, 1);
    }
    std::copy(start, input.end(), std::ostream_iterator<unsigned int>(result, ""));
    return result.str();
}

vector<string> getExpectedResults_Bytea(const vector<string> &input) {
  vector<string> ret = {};

  for (int i = 0; i < input.size(); i++) {
    ret.push_back(stringToHex(input[i]));
  }

  return ret;
}

double stringToDouble(const string &value) {
  if (value == "NULL") {
    // Return a dummy value of zero.
    return 0;
  }
  return atof(value.c_str());
}

vector<double> getExpectedResults_Double(const vector<string> &data) {
  vector<double> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(stringToDouble(data[i]));
  }

  return expectedResults;
}

int stringToInt(const string &value) {
  if (value == "NULL") {
    // Return a dummy value of zero.
    return 0;
  }
  return std::stoi(value.c_str(), NULL, 10);
}

vector<int> getExpectedResults_Int(const vector<string> &data) {
  vector<int> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(stringToInt(data[i]));
  }
  return expectedResults;
}

short int stringToShortInt(const string &value) {
  if (value == "NULL") {
    // Return a dummy value of zero.
    return 0;
  }
  int full_size = std::stoi(value.c_str(), NULL, 10);

  // Convert to short int
  if (full_size <= static_cast<int>(INT16_MAX) && full_size >= static_cast<int>(INT16_MIN)) {
    return static_cast<short int>(full_size);
  }

  // Conversion failed / out of range, return dummy value
  return 0;
}

vector<short int> getExpectedResults_ShortInt(const vector<string> &data) {
  vector<short int> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(stringToShortInt(data[i]));
  }
  return expectedResults;
}

float stringToFloat(const string &value) {
  if (value == "NULL") {
    // Return a dummy value of zero.
    return 0;
  }
  return stof(value);
}

vector<float> getExpectedResults_Float(const vector<string> &data) {
  vector<float> expectedResults{};

  for (int i = 0; i < data.size(); i++) {
    expectedResults.push_back(stringToFloat(data[i]));
  }

  return expectedResults;
}

string stringToTime(const string &input, const int timeBytesExpected) {
  string ret = string(input);
  if (strcmp(input.data(), "NULL") == 0) {
    return ret;
  }

  size_t period_pos = ret.find('.');
  if (period_pos == std::string::npos) {
    ret.append(".");
  }
  unsigned int padding = timeBytesExpected - ret.length();
  ret.append(string(padding, '0'));
  return ret;
}

vector<string> getExpectedResults_Time(const vector<string> &input, const int timeBytesExpected) {
  vector<string> ret = {};

  for (int i = 0; i < input.size(); i++) {
    ret.push_back(stringToTime(input[i], timeBytesExpected));
  }

  return ret;
}

string hexToIntStr(const string &input) {
  int i;
  std::istringstream iss(input);
  iss >> std::hex >> i;

  return std::to_string(i);
}

string padString(string input, size_t table_size) {
  std::ostringstream result;
  result << std::left << std::setw(table_size) << std::setfill(' ') << input;
  return result.str();
}

vector<string> getExpectedResults_Char(const vector<string> &input, size_t table_size) {
  vector<string> ret = {};

  for (int i = 0; i < input.size(); i++) {
    ret.push_back(padString(input[i], table_size));
  }

  return ret;
}
