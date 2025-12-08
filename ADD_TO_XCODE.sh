#!/bin/bash
# Script to add Mission Control files to Xcode project

echo "🚀 Adding Mission Control files to Xcode project..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "${BLUE}Mission Control Files Created:${NC}"
echo "  ✓ MissionControlViewModel.swift"
echo "  ✓ WorkoutMissionControlView.swift"
echo "  ✓ ProjectedFinishBanner.swift"
echo "  ✓ CompletedSegmentCard.swift"
echo "  ✓ LiveSegmentCard.swift"
echo "  ✓ UpcomingSegmentCard.swift"
echo "  ✓ PaceDegradationGraph.swift"
echo "  ✓ HRZonesCard.swift"
echo "  ✓ AIInsightsCard.swift"
echo "  ✓ PerformanceStatsCard.swift"
echo ""

echo "${GREEN}📝 TO ADD TO XCODE:${NC}"
echo ""
echo "1. Open FLEXR.xcodeproj in Xcode"
echo ""
echo "2. Right-click on 'Features/Workout' folder"
echo ""
echo "3. Select 'Add Files to FLEXR...'"
echo ""
echo "4. Navigate to and select:"
echo "   FLEXR/Sources/Features/Workout/MissionControl"
echo ""
echo "5. Make sure these options are checked:"
echo "   ☑ Copy items if needed"
echo "   ☑ Create groups"
echo "   ☑ Add to target: FLEXR"
echo ""
echo "6. Click 'Add'"
echo ""
echo "${GREEN}✅ All 10 files will be added automatically!${NC}"
echo ""
echo "Then just build and run! 🚀"
echo ""
