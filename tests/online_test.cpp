// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Tommy McLeroy. Part of recomp-common: https://github.com/tmcleroy/recomp-common
#include "../launcher/src/online.cpp"
#include <cassert>
#include <iostream>

int main() {
    const auto matches = launcher::Matches(R"({"matches":[{"game":"example","code":"ABC234","name":"Host","watching":true},{"game":"example","code":"DEF567","name":"Other","watching":false}]})");
    assert(matches.size() == 2);
    assert(matches[0].watching && !matches[1].watching);
    const auto old = launcher::Matches(R"({"matches":[{"code":"ABC234","name":"Old server"}]})");
    assert(old.size() == 1 && !old[0].watching);
    std::cout << "ok: running matches offer Watch; waiting and older listings remain Join\n";
}
