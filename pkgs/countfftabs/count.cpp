#include <iostream>
#include <fstream>
#include <endian.h>

#include <simdjson.h>
#include <lz4.h>
using namespace simdjson;
// /home/yorick/.mozilla/firefox/sdgle03g.default/sessionstore-backups/recovery.jsonlz4
// jq '.windows | map(.tabs | length) | add'

padded_string read_mozlz4a_file(const std::string& file) {
  std::ifstream is(file, std::ifstream::binary);
  if (!is) {
    std::cerr << "error opening file" << std::endl;
    exit(1);
  }
  is.seekg(0, is.end);
  size_t insz = is.tellg();
  is.seekg(0, is.beg);
  char * buffer = new char[insz];
  is.read(buffer, insz);
  if (!is) {
    std::cerr << "error reading file" << std::endl;
    exit(1);
  }
  is.close();
  if (memcmp(buffer, "mozLz40", 8)) {
    std::cerr << "not a mozLZa file" << std::endl;
    exit(1);
  }
  size_t outsz = le32toh(*(uint32_t *) (buffer + 8));
  padded_string out(outsz);
  if (LZ4_decompress_safe_partial(buffer + 12, out.data(), insz - 12, outsz, outsz) < 0) {
    std::cerr << "decompression error" << std::endl;
    exit(1);
  }
  return out;
}

std::string get_default_firefox_profile_path() {
    std::string path = std::string(std::getenv("HOME")) + "/.mozilla/firefox/profiles.ini";
    std::ifstream file(path);
    if (file.is_open()) {
        std::string line;
        bool found = false;
        std::string default_profile;
        while (std::getline(file, line)) {
            if (line.find("[General]") == 0) {
                found = true;
            } else if (found && line.find("Default=") == 0) {
                default_profile = line.substr(8);
                break;
            }
        }
        file.close();
        if (!default_profile.empty()) {
            std::stringstream ss;
            ss << std::string(std::getenv("HOME")) << "/.mozilla/firefox/" << default_profile;
            return ss.str();
        }
    }
    return "";
}

int main(int ac, char **av) {
    ondemand::parser parser;
    std::string path = get_default_firefox_profile_path();
    if (ac < 2 && path.empty()) {
      std::cerr << "Could not find default Firefox profile" << std::endl;
      std::cerr << "usage: " << av[0] << " .mozilla/firefox/*.default/sessionstore-backups/recovery.jsonlz4" << std::endl;
      exit(1);
    }
    
    padded_string json = read_mozlz4a_file(ac > 1 ? av[1] : path + "/sessionstore-backups/recovery.jsonlz4");
    ondemand::document session = parser.iterate(json);
    ondemand::array windows = session["windows"];
    size_t n = 0;
    for (auto i : windows) {
      ondemand::array tabs = i["tabs"];
      n += tabs.count_elements();
    }
    std::cout << n << std::endl;
}
