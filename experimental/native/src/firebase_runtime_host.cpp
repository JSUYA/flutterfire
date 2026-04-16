#include "http_client.h"

#include <iostream>
#include <string>
#include <vector>

namespace firebase = firebase_tizen_experimental;

namespace {

class RuntimeHost {
 public:
  int Run() {
    std::string line;
    while (std::getline(std::cin, line)) {
      const int result = HandleCommand(firebase::TrimLine(line));
      if (result != 0) {
        return result;
      }
    }
    return 0;
  }

 private:
  int HandleCommand(const std::string& line) {
    const std::vector<std::string> parts = firebase::SplitTabs(line);
    if (parts.empty()) {
      WriteError("Empty command");
      return 0;
    }

    if (parts[0] == "INIT") {
      return HandleInit(parts);
    }
    if (parts[0] == "SIGN_IN") {
      return HandleSignIn(parts);
    }
    if (parts[0] == "CALLABLE") {
      return HandleCallable(parts);
    }
    if (parts[0] == "DISPOSE") {
      WriteOk("disposed");
      return 1;
    }

    WriteError("Unknown command: " + parts[0]);
    return 0;
  }

  int HandleInit(const std::vector<std::string>& parts) {
    if (parts.size() != 2) {
      WriteError("INIT requires sign-in URL");
      return 0;
    }
    if (!firebase::Base64Decode(parts[1], &sign_in_url_)) {
      WriteError("INIT sign-in URL was not valid base64");
      return 0;
    }
    WriteOk("initialized");
    return 0;
  }

  int HandleSignIn(const std::vector<std::string>& parts) {
    if (sign_in_url_.empty()) {
      WriteError("Runtime not initialized");
      return 0;
    }
    if (parts.size() != 3) {
      WriteError("SIGN_IN requires email and password");
      return 0;
    }

    std::string email;
    std::string password;
    if (!firebase::Base64Decode(parts[1], &email) ||
        !firebase::Base64Decode(parts[2], &password)) {
      WriteError("SIGN_IN arguments were not valid base64");
      return 0;
    }

    const std::string body =
        "{\"email\":\"" + firebase::EscapeJson(email) + "\","
        "\"password\":\"" + firebase::EscapeJson(password) + "\","
        "\"returnSecureToken\":true}";
    const firebase::HttpResponse response = firebase::PostJson(sign_in_url_, body);
    if (!response.transport_error.empty()) {
      WriteError(response.transport_error);
      return 0;
    }

    if (response.status_code >= 200 && response.status_code < 300) {
      id_token_ = firebase::ExtractJsonStringField(response.body, "idToken");
    }

    WriteOk(std::to_string(response.status_code), response.body);
    return 0;
  }

  int HandleCallable(const std::vector<std::string>& parts) {
    if (parts.size() != 3) {
      WriteError("CALLABLE requires URL and payload");
      return 0;
    }

    std::string url;
    std::string payload;
    if (!firebase::Base64Decode(parts[1], &url) ||
        !firebase::Base64Decode(parts[2], &payload)) {
      WriteError("CALLABLE arguments were not valid base64");
      return 0;
    }

    std::vector<firebase::Header> headers;
    if (!id_token_.empty()) {
      headers.push_back(firebase::Header{"Authorization", "Bearer " + id_token_});
    }

    const firebase::HttpResponse response =
        firebase::PostJson(url, payload, headers);
    if (!response.transport_error.empty()) {
      WriteError(response.transport_error);
      return 0;
    }

    WriteOk(std::to_string(response.status_code), response.body);
    return 0;
  }

  void WriteOk(const std::string& message, const std::string& body = "") {
    std::cout << "OK\t" << firebase::Base64Encode(message) << '\t'
              << firebase::Base64Encode(body) << '\n';
    std::cout.flush();
  }

  void WriteError(const std::string& message) {
    std::cout << "ERR\t" << firebase::Base64Encode(message) << '\n';
    std::cout.flush();
  }

  std::string sign_in_url_;
  std::string id_token_;
};

}  // namespace

int main() {
  RuntimeHost host;
  const int run_result = host.Run();
  if (run_result == 1) {
    return 0;
  }
  return run_result;
}
