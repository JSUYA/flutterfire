#pragma once

#include <string>
#include <vector>

namespace firebase_tizen_experimental {

struct Header {
  std::string name;
  std::string value;
};

struct HttpResponse {
  long status_code = 0;
  std::string body;
  std::string transport_error;
};

HttpResponse PostJson(const std::string& url, const std::string& body,
                      const std::vector<Header>& headers = {});

std::string EscapeJson(const std::string& value);
std::string Base64Encode(const std::string& value);
bool Base64Decode(const std::string& input, std::string* output);
std::vector<std::string> SplitTabs(const std::string& input);
std::string TrimLine(std::string value);
std::string ExtractJsonStringField(const std::string& json,
                                   const std::string& field_name);

}  // namespace firebase_tizen_experimental
