/**************************************************************************/
/*  visionos_spatial_events.mm                                            */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

#include "servers/xr/xr_controller_tracker.h"
#include "servers/xr/xr_positional_tracker.h"
#include "servers/xr/xr_server.h"

#include <stdio.h>
#ifdef VISIONOS_ENABLED

#include "visionos_spatial_events.h"

void VisionOSSpatialEventTracking::initialize(XRServer *p_xr_server) {
	left_hand.tracker.instantiate();
	left_hand.tracker->set_tracker_hand(XRPositionalTracker::TRACKER_HAND_LEFT);
	left_hand.tracker->set_tracker_name("left_hand");
	left_hand.tracker->set_tracker_desc("visionOS Left Hand Spatial Event");
	p_xr_server->add_tracker(left_hand.tracker);

	right_hand.tracker.instantiate();
	right_hand.tracker->set_tracker_hand(XRPositionalTracker::TRACKER_HAND_RIGHT);
	right_hand.tracker->set_tracker_name("right_hand");
	right_hand.tracker->set_tracker_desc("visionOS Left Hand Spatial Event");
	p_xr_server->add_tracker(right_hand.tracker);

	ray.instantiate();
	ray->set_tracker_name("eye");
	ray->set_tracker_desc("visionOS Selection Ray");
	p_xr_server->add_tracker(ray);
}

namespace {

void uninitialize_tracker(Ref<XRControllerTracker> &p_tracker, XRServer *p_xr_server) {
	if (p_tracker.is_valid()) {
		p_xr_server->remove_tracker(p_tracker);
		p_tracker.unref();
	}
}

} // namespace

void VisionOSSpatialEventTracking::uninitialize(XRServer *p_xr_server) {
	if (p_xr_server) {
		uninitialize_tracker(left_hand.tracker, p_xr_server);
		uninitialize_tracker(right_hand.tracker, p_xr_server);
		uninitialize_tracker(ray, p_xr_server);
	}
}

void VisionOSSpatialEventTracking::on_spatial_event(const VisionOSSpatialEvent &p_event) {
	const bool active = (p_event.phase == VisionOSSpatialEvent::Phase::active);
	// Hand
	Hand *hand = nullptr;
	switch (p_event.chirality) {
		case VisionOSSpatialEvent::Chirality::left:
			hand = &left_hand;
			break;
		case VisionOSSpatialEvent::Chirality::right:
			hand = &right_hand;
			break;
		default:
			break;
	}
	if (hand) {
		hand->tracker->set_pose("default", p_event.hand_pose, Vector3(), Vector3());
		hand->tracker->set_input("trigger_click", active);

		if (active) {
			if (p_event.has_ray && !hand->has_submitted_ray) {
				hand->has_submitted_ray = true;
				ray->set_pose("default", p_event.ray, Vector3(), Vector3());
			}
		} else {
			hand->tracker->invalidate_pose("default");
			hand->has_submitted_ray = false;
		}
		ray->set_input("trigger_click", active);
	}
}

#endif // VISIONOS_ENABLED
