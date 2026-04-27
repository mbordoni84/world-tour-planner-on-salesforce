public with sharing class StaffingAgentActions {

    // Shared helper
    public static String formatTime(Time t) {
        if (t == null) return '--:--';
        return String.valueOf(t.hour()).leftPad(2, '0') + ':' +
               String.valueOf(t.minute()).leftPad(2, '0');
    }
}
