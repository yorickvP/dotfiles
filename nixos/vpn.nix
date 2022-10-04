{
  ips = {
    pennyworth = "10.209.0.1";
    jarvis = "10.209.0.2";
    frumar = "10.209.0.3";
    blackadder = "10.209.0.6";
    smithers = "10.209.0.8";
  };
  keys = {
    # for i in wg.*.key; do echo $(echo $i | cut -d. -f2) = \"$(wg pubkey < $i)\"\;; done
    blackadder = "+SfIbW9/MmA5iIVUUzkKPeWmZvwhP8y9qWo67o2UZUA=";
    frumar = "UpFw4KmrvmOWdMOJ+LHvMzgN7cQMnasqlkzF8/apoGI=";
    jarvis = "2/Qaq5uiy8uGGnZLIfjeomL47XjZCsJ1dDFDD9Nlq3E=";
    pennyworth = "XoeUMsiSOWBFEFuAu+S4iQd3MzkyGhIj9dtxzZ0I500=";
    smithers = "CXsx26Xi+mBeuB6U8hdeuOBC3o4gTnBc6biez/BCqzM=";
  };
}
