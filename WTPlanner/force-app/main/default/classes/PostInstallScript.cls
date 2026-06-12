global class PostInstallScript implements InstallHandler {
    global void onInstall(InstallContext ctx) {
        // Skip if demo data already exists
        if ([SELECT COUNT() FROM Event__c WHERE Name = 'World Tour Demo Event'] > 0) return;

        Event__c ev = new Event__c(Name = 'World Tour Demo Event');
        insert ev;

        Session_Type__c st_Agentforce_City = new Session_Type__c(Name = 'Agentforce City', Event__c = ev.Id);
        Session_Type__c st_Agentforce_Labs = new Session_Type__c(Name = 'Agentforce Labs', Event__c = ev.Id);
        Session_Type__c st_Booth = new Session_Type__c(Name = 'Booth', Event__c = ev.Id);
        Session_Type__c st_Breakout = new Session_Type__c(Name = 'Breakout', Event__c = ev.Id);
        Session_Type__c st_Community_Networking = new Session_Type__c(Name = 'Community Networking', Event__c = ev.Id);
        Session_Type__c st_Keynote = new Session_Type__c(Name = 'Keynote', Event__c = ev.Id);
        Session_Type__c st_Theatre = new Session_Type__c(Name = 'Theatre', Event__c = ev.Id);
        Session_Type__c st_Trailhead = new Session_Type__c(Name = 'Trailhead', Event__c = ev.Id);
        Session_Type__c st_WorkshopHOTs = new Session_Type__c(Name = 'Workshop (HOTs)', Event__c = ev.Id);
        insert new List<Session_Type__c>{st_Agentforce_City, st_Agentforce_Labs, st_Booth, st_Breakout, st_Community_Networking, st_Keynote, st_Theatre, st_Trailhead, st_WorkshopHOTs};

        List<Session__c> sessionList = new List<Session__c>();
        sessionList.add(new Session__c(Name = 'Accenture', Session_Type__c = st_Breakout.Id, Min_Shifts__c = 1, Max_Shifts__c = 3));
        sessionList.add(new Session__c(Name = 'Agentforce', Session_Type__c = st_Booth.Id, Min_Shifts__c = 1, Max_Shifts__c = 6));
        sessionList.add(new Session__c(Name = 'Agentforce - Superdemo', Session_Type__c = st_Booth.Id, Min_Shifts__c = 1, Max_Shifts__c = 7));
        sessionList.add(new Session__c(Name = 'Agentforce Labs - Reception', Session_Type__c = st_Agentforce_Labs.Id, Min_Shifts__c = 1, Max_Shifts__c = 5));
        sessionList.add(new Session__c(Name = 'Agentforce Labs Support', Session_Type__c = st_Agentforce_Labs.Id, Min_Shifts__c = 1, Max_Shifts__c = 6));
        sessionList.add(new Session__c(Name = 'Agentic Enterprise Experience', Session_Type__c = st_Theatre.Id, Min_Shifts__c = 1, Max_Shifts__c = 7));
        sessionList.add(new Session__c(Name = 'Amplize', Session_Type__c = st_Breakout.Id, Min_Shifts__c = 1, Max_Shifts__c = 3));
        sessionList.add(new Session__c(Name = 'City Storefront 1 - Leapmotor', Session_Type__c = st_Agentforce_City.Id, Min_Shifts__c = 1, Max_Shifts__c = 5));
        sessionList.add(new Session__c(Name = 'City Storefront 2 - Trenitalia', Session_Type__c = st_Agentforce_City.Id, Min_Shifts__c = 1, Max_Shifts__c = 5));
        sessionList.add(new Session__c(Name = 'Get Started with AF Builder and Agent Script (HOT)', Session_Type__c = st_WorkshopHOTs.Id, Min_Shifts__c = 1, Max_Shifts__c = 4));
        sessionList.add(new Session__c(Name = 'Get Started with Data 360 (HOT)', Session_Type__c = st_WorkshopHOTs.Id, Min_Shifts__c = 1, Max_Shifts__c = 4));
        sessionList.add(new Session__c(Name = 'Keynote Backup Speakers', Session_Type__c = st_Keynote.Id, Min_Shifts__c = 1, Max_Shifts__c = 3));
        sessionList.add(new Session__c(Name = 'Keynote Presentation', Session_Type__c = st_Keynote.Id, Min_Shifts__c = 1, Max_Shifts__c = 3));
        sessionList.add(new Session__c(Name = 'Theatre 1 - B2B Commerce', Session_Type__c = st_Theatre.Id, Min_Shifts__c = 1, Max_Shifts__c = 3));
        sessionList.add(new Session__c(Name = 'Trailblazer Community Networking', Session_Type__c = st_Community_Networking.Id, Min_Shifts__c = 1, Max_Shifts__c = 4));
        sessionList.add(new Session__c(Name = 'Trailhead Area', Session_Type__c = st_Trailhead.Id, Min_Shifts__c = 1, Max_Shifts__c = 7));
        insert sessionList;

        Map<String, Session__c> sessionByName = new Map<String, Session__c>();
        for (Session__c s : sessionList) sessionByName.put(s.Name, s);

        List<Shift__c> shifts = new List<Shift__c>();
        shifts.add(new Shift__c(Session__c = sessionByName.get('Accenture').Id, Start_Time__c = Time.newInstance(15,45,0,0), End_Time__c = Time.newInstance(16,15,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce').Id, Start_Time__c = Time.newInstance(8,30,0,0), End_Time__c = Time.newInstance(10,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce').Id, Start_Time__c = Time.newInstance(11,20,0,0), End_Time__c = Time.newInstance(14,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce').Id, Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(17,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce - Superdemo').Id, Start_Time__c = Time.newInstance(11,30,0,0), End_Time__c = Time.newInstance(12,10,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce - Superdemo').Id, Start_Time__c = Time.newInstance(12,10,0,0), End_Time__c = Time.newInstance(12,50,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce - Superdemo').Id, Start_Time__c = Time.newInstance(12,50,0,0), End_Time__c = Time.newInstance(13,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce - Superdemo').Id, Start_Time__c = Time.newInstance(13,30,0,0), End_Time__c = Time.newInstance(14,25,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce - Superdemo').Id, Start_Time__c = Time.newInstance(14,25,0,0), End_Time__c = Time.newInstance(15,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce Labs - Reception').Id, Start_Time__c = Time.newInstance(11,30,0,0), End_Time__c = Time.newInstance(13,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce Labs - Reception').Id, Start_Time__c = Time.newInstance(13,30,0,0), End_Time__c = Time.newInstance(15,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce Labs - Reception').Id, Start_Time__c = Time.newInstance(15,30,0,0), End_Time__c = Time.newInstance(17,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce Labs Support').Id, Start_Time__c = Time.newInstance(11,30,0,0), End_Time__c = Time.newInstance(13,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce Labs Support').Id, Start_Time__c = Time.newInstance(13,30,0,0), End_Time__c = Time.newInstance(15,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentforce Labs Support').Id, Start_Time__c = Time.newInstance(15,30,0,0), End_Time__c = Time.newInstance(17,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentic Enterprise Experience').Id, Start_Time__c = Time.newInstance(11,45,0,0), End_Time__c = Time.newInstance(12,5,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentic Enterprise Experience').Id, Start_Time__c = Time.newInstance(12,20,0,0), End_Time__c = Time.newInstance(12,40,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentic Enterprise Experience').Id, Start_Time__c = Time.newInstance(12,55,0,0), End_Time__c = Time.newInstance(13,15,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentic Enterprise Experience').Id, Start_Time__c = Time.newInstance(13,30,0,0), End_Time__c = Time.newInstance(13,50,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Agentic Enterprise Experience').Id, Start_Time__c = Time.newInstance(14,25,0,0), End_Time__c = Time.newInstance(14,45,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Amplize').Id, Start_Time__c = Time.newInstance(13,20,0,0), End_Time__c = Time.newInstance(13,50,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('City Storefront 1 - Leapmotor').Id, Start_Time__c = Time.newInstance(8,30,0,0), End_Time__c = Time.newInstance(13,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('City Storefront 1 - Leapmotor').Id, Start_Time__c = Time.newInstance(13,0,0,0), End_Time__c = Time.newInstance(15,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('City Storefront 1 - Leapmotor').Id, Start_Time__c = Time.newInstance(15,0,0,0), End_Time__c = Time.newInstance(17,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('City Storefront 2 - Trenitalia').Id, Start_Time__c = Time.newInstance(8,30,0,0), End_Time__c = Time.newInstance(13,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('City Storefront 2 - Trenitalia').Id, Start_Time__c = Time.newInstance(13,0,0,0), End_Time__c = Time.newInstance(15,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('City Storefront 2 - Trenitalia').Id, Start_Time__c = Time.newInstance(15,0,0,0), End_Time__c = Time.newInstance(17,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Get Started with AF Builder and Agent Script (HOT)').Id, Start_Time__c = Time.newInstance(12,40,0,0), End_Time__c = Time.newInstance(13,40,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Get Started with AF Builder and Agent Script (HOT)').Id, Start_Time__c = Time.newInstance(15,10,0,0), End_Time__c = Time.newInstance(16,10,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Get Started with Data 360 (HOT)').Id, Start_Time__c = Time.newInstance(11,30,0,0), End_Time__c = Time.newInstance(12,30,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Get Started with Data 360 (HOT)').Id, Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(15,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Keynote Backup Speakers').Id, Start_Time__c = Time.newInstance(10,0,0,0), End_Time__c = Time.newInstance(12,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Keynote Presentation').Id, Start_Time__c = Time.newInstance(9,0,0,0), End_Time__c = Time.newInstance(12,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Theatre 1 - B2B Commerce').Id, Start_Time__c = Time.newInstance(15,30,0,0), End_Time__c = Time.newInstance(15,50,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Trailblazer Community Networking').Id, Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(15,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Trailblazer Community Networking').Id, Start_Time__c = Time.newInstance(15,0,0,0), End_Time__c = Time.newInstance(16,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Trailhead Area').Id, Start_Time__c = Time.newInstance(8,30,0,0), End_Time__c = Time.newInstance(10,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Trailhead Area').Id, Start_Time__c = Time.newInstance(11,30,0,0), End_Time__c = Time.newInstance(14,0,0,0)));
        shifts.add(new Shift__c(Session__c = sessionByName.get('Trailhead Area').Id, Start_Time__c = Time.newInstance(14,15,0,0), End_Time__c = Time.newInstance(17,0,0,0)));
        insert shifts;
    }
}
