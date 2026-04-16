#include "http_client.h"

#include <curl/curl.h>

#include <cctype>
#include <cstdlib>
#include <sstream>

namespace firebase_tizen_experimental {

namespace {

size_t WriteCallback(char* ptr, size_t size, size_t nmemb, void* userdata) {
  auto* buffer = static_cast<std::string*>(userdata);
  const size_t total_size = size * nmemb;
  buffer->append(ptr, total_size);
  return total_size;
}

struct CurlGlobalInit {
  CurlGlobalInit() { curl_global_init(CURL_GLOBAL_DEFAULT); }
  ~CurlGlobalInit() { curl_global_cleanup(); }
};

CurlGlobalInit g_curl_init;

bool IsBase64Char(unsigned char value) {
  return std::isalnum(value) || value == '+' || value == '/';
}

}  // namespace

HttpResponse PostJson(const std::string& url, const std::string& body,
                      const std::vector<Header>& headers) {
  HttpResponse response;
  CURL* curl = curl_easy_init();
  if (curl == nullptr) {
    response.transport_error = "curl_easy_init failed";
    return response;
  }

  std::string response_body;
  struct curl_slist* curl_headers = nullptr;
  curl_headers = curl_slist_append(curl_headers, "Content-Type: application/json");
  for (const Header& header : headers) {
    std::string value = header.name + ": " + header.value;
    curl_headers = curl_slist_append(curl_headers, value.c_str());
  }

  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_HTTPHEADER, curl_headers);
  curl_easy_setopt(curl, CURLOPT_POST, 1L);
  curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body.c_str());
  curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, body.size());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_body);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);

  const CURLcode result = curl_easy_perform(curl);
  if (result != CURLE_OK) {
    response.transport_error = curl_easy_strerror(result);
  } else {
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response.status_code);
    response.body = std::move(response_body);
  }

  curl_slist_free_all(curl_headers);
  curl_easy_cleanup(curl);
  return response;
}

std::string EscapeJson(const std::string& value) {
  std::ostringstream stream;
  for (char character : value) {
    switch (character) {
      case '\\':
        stream << "\\\\";
        break;
      case '"':
        stream << "\\\"";
        break;
      case '\b':
        stream << "\\b";
        break;
      case '\f':
        stream << "\\f";
        break;
      case '\n':
        stream << "\\n";
        break;
      case '\r':
        stream << "\\r";
        break;
      case '\t':
        stream << "\\t";
        break;
      default:
        if (static_cast<unsigned char>(character) < 0x20) {
          stream << "\\u";
          stream.width(4);
          stream.fill('0');
          stream << std::hex << static_cast<int>(character) << std::dec;
        } else {
          stream << character;
        }
        break;
    }
  }
  return stream.str();
}

std::string Base64Encode(const std::string& value) {
  static constexpr char table[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  std::string output;
  int bit_count = 0;
  unsigned int bit_buffer = 0;
  for (unsigned char character : value) {
    bit_buffer = (bit_buffer << 8U) | character;
    bit_count += 8;
    while (bit_count >= 6) {
      output.push_back(table[(bit_buffer >> (bit_count - 6)) & 0x3F]);
      bit_count -= 6;
    }
  }
  if (bit_count > 0) {
    bit_buffer <<= (6 - bit_count);
    output.push_back(table[bit_buffer & 0x3F]);
  }
  while (output.size() % 4 != 0) {
    output.push_back('=');
  }
  return output;
}

bool Base64Decode(const std::string& input, std::string* output) {
  static constexpr char table[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  output->clear();
  int bit_count = 0;
  unsigned int bit_buffer = 0;

  for (unsigned char character : input) {
    if (character == '=') {
      break;
    }
    if (!IsBase64Char(character)) {
      continue;
    }
    const char* found = std::strchr(table, character);
    if (found == nullptr) {
      return false;
    }
    bit_buffer = (bit_buffer << 6U) | static_cast<unsigned int>(found - table);
    bit_count += 6;
    if (bit_count >= 8) {
      output->push_back(static_cast<char>((bit_buffer >> (bit_count - 8)) & 0xFF));
      bit_count -= 8;
    }
  }

  return true;
}

std::vector<std::string> SplitTabs(const std::string& input) {
  std::vector<std::string> parts;
  std::string current;
  for (char character : input) {
    if (character == '\t') {
      parts.push_back(current);
      current.clear();
      continue;
    }
    current.push_back(character);
  }
  parts.push_back(current);
  return parts;
}

std::string TrimLine(std::string value) {
  while (!value.empty() &&
         (value.back() == '\n' || value.back() == '\r')) {
    value.pop_back();
  }
  return value;
}

std::string ExtractJsonStringField(const std::string& json,
                                   const std::string& field_name) {
  const std::string needle = "\"" + field_name + "\"";
  const std::size_t field_index = json.find(needle);
  if (field_index == std::string::npos) {
    return "";
  }
  const std::size_t colon_index = json.find(':', field_index + needle.size());
  if (colon_index == std::string::npos) {
    return "";
  }
  std::size_t quote_index = json.find('"', colon_index + 1);
  if (quote_index == std::string::npos) {
    return "";
  }
  ++quote_index;
  std::string value;
  bool escaping = false;
  for (std::size_t index = quote_index; index < json.size(); ++index) {
    const char character = json[index];
    if (escaping) {
      value.push_back(character);
      escaping = false;
      continue;
    }
    if (character == '\\') {
      escaping = true;
      continue;
    }
    if (character == '"') {
      return value;
    }
    value.push_back(character);
  }
  return "";
}

}  // namespace firebase_tizen_experimental
