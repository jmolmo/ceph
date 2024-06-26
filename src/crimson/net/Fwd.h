// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Copyright (C) 2017 Red Hat, Inc
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */

#pragma once

#include <boost/container/small_vector.hpp>
#include <seastar/core/future.hh>
#include <seastar/core/future-util.hh>
#include <seastar/core/shared_ptr.hh>
#include <seastar/core/sharded.hh>

#include "msg/Connection.h"
#include "msg/MessageRef.h"
#include "msg/msg_types.h"

#include "crimson/common/errorator.h"

using auth_proto_t = int;

class AuthConnectionMeta;
using AuthConnectionMetaRef = seastar::lw_shared_ptr<AuthConnectionMeta>;

namespace crimson::net {

using msgr_tag_t = uint8_t;
using stop_t = seastar::stop_iteration;

class Connection;
using ConnectionRef = seastar::shared_ptr<Connection>;
using ConnectionFRef = seastar::foreign_ptr<ConnectionRef>;

class Dispatcher;
class ChainedDispatchers;
constexpr std::size_t NUM_DISPATCHERS = 4u;
using dispatchers_t = boost::container::small_vector<Dispatcher*, NUM_DISPATCHERS>;

class Messenger;
using MessengerRef = seastar::shared_ptr<Messenger>;

} // namespace crimson::net
