{
  ips = {
    pennyworth = "10.209.0.1";
    jarvis = "10.209.0.2";
    frumar = "10.209.0.3";
    woodhouse = "10.209.0.4";
    ascanius = "10.209.0.5";
    blackadder = "10.209.0.6";
    zazu = "10.209.0.7";
  };
  keys = {
    # for i in wg.*.key; do echo $(echo $i | cut -d. -f2) = \"$(wg pubkey < $i)\"\;; done
    ascanius = "zZ3gegDspSKBJutp99VzODZNcJ1qQF3OH2nrlxhICwI=";
    blackadder = "+SfIbW9/MmA5iIVUUzkKPeWmZvwhP8y9qWo67o2UZUA=";
    frumar = "UpFw4KmrvmOWdMOJ+LHvMzgN7cQMnasqlkzF8/apoGI=";
    jarvis = "2/Qaq5uiy8uGGnZLIfjeomL47XjZCsJ1dDFDD9Nlq3E=";
    pennyworth = "XoeUMsiSOWBFEFuAu+S4iQd3MzkyGhIj9dtxzZ0I500=";
    woodhouse = "ICzlnC4zKUYvpQ0o5AFq2rG7CCqWUFVn3UqkLSoYNgI=";
    zazu = "6X5EdNMO1MtFi18LCRGZ2cBD0d50Wq+pwkwVubjY1Ew=";
  };
}
