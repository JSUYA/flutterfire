#include "http_client.h"

#include <iostream>
#include <string>
#include <vector>

namespace firebase = firebase_tizen_experimental;

namespace {

std::string ReadOption(const std::vector<std::string>& arguments,
                       const std::string& name) {
  for (std::size_t index = 0; index + 1 < arguments.size(); ++index) {
    if (arguments[index] == name) {
      return arguments[index + 1];
    }
  }
  return "";
}

int WriteResponse(const firebase::HttpResponse& response) {
  std::cout << "STATUS\t" << response.status_code << '\n';
  std::cout << "BODY\t" << firebase::Base64Encode(response.body) << '\n';
  std::cout << "ERROR\t" << firebase::Base64Encode(response.transport_error) << '\n';
  return response.transport_error.empty() ? 0 : 1;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 2) {
    std::cerr << "Missing command\n";
    return 64;
  }

  const std::string command = argv[1];
  std::vector<std::string> arguments;
  for (int index = 2; index < argc; ++index) {
    arguments.emplace_back(argv[index]);
  }

  const std::string url = ReadOption(arguments, "--url");
  const std::string body_base64 = ReadOption(arguments, "--body-base64");
  if (url.empty() || body_base64.empty()) {
    std::cerr << "Missing --url or --body-base64\n";
    return 64;
  }

  std::string body;
  if (!firebase::Base64Decode(body_base64, &body)) {
    std::cerr << "Invalid base64 request body\n";
    return 64;
  }

  std::vector<firebase::Header> headers;
  const std::string bearer = ReadOption(arguments, "--bearer");
  if (!bearer.empty()) {
    headers.push_back(firebase::Header{"Authorization", "Bearer " + bearer});
  }

  if (command != "sign-in" && command != "callable") {
    std::cerr << "Unknown command: " << command << '\n';
    return 64;
  }

  return WriteResponse(firebase::PostJson(url, body, headers));
}
