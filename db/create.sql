SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA archive;
CREATE SCHEMA stats;
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
SET search_path = archive, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE pageviews (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    ip inet NOT NULL,
    referer character varying,
    controller character varying,
    action character varying,
    medium character varying,
    campaign character varying,
    model_id character varying,
    url character varying,
    visitor_id character varying,
    session_id character varying,
    user_agent character varying,
    user_id integer,
    flash_error character varying,
    abtest_treatment character varying,
    portal_id integer,
    source character varying,
    ads_shown character varying
);
CREATE TABLE tracker_items (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    lastseen_on timestamp without time zone NOT NULL,
    is_tracked boolean NOT NULL,
    notification_sent_on timestamp without time zone
);
CREATE TABLE treated_visitors (
    id integer NOT NULL,
    ab_test_id integer NOT NULL,
    visitor_id character varying NOT NULL,
    treatment integer NOT NULL,
    user_id integer
);
SET search_path = public, pg_catalog;
CREATE SEQUENCE ab_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE ab_tests (
    id integer DEFAULT nextval('ab_tests_id_seq'::regclass) NOT NULL,
    name character varying NOT NULL,
    treatments integer NOT NULL,
    finished boolean DEFAULT false NOT NULL,
    minimum_difference numeric(10,2),
    metrics character varying,
    info_url character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    completed_on timestamp without time zone,
    min_difference numeric(10,2) DEFAULT 0.05 NOT NULL,
    cache_conversion_rates character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    dirty boolean DEFAULT true NOT NULL,
    cache_expected_completion_date timestamp without time zone,
    active boolean DEFAULT true NOT NULL
);
CREATE TABLE ads (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    file character varying,
    link_file character varying,
    html character varying,
    advertiser_id integer
);
CREATE SEQUENCE ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ads_id_seq OWNED BY ads.id;
CREATE TABLE ads_slots (
    id integer NOT NULL,
    name character varying NOT NULL,
    location character varying NOT NULL,
    behaviour_class character varying NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    advertiser_id integer,
    image_dimensions character varying
);
CREATE SEQUENCE ads_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ads_slots_id_seq OWNED BY ads_slots.id;
CREATE TABLE ads_slots_instances (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ads_slot_id integer NOT NULL,
    ad_id integer NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE ads_slots_instances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ads_slots_instances_id_seq OWNED BY ads_slots_instances.id;
CREATE TABLE ads_slots_portals (
    id integer NOT NULL,
    ads_slot_id integer NOT NULL,
    portal_id integer NOT NULL
);
CREATE SEQUENCE ads_slots_portals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ads_slots_portals_id_seq OWNED BY ads_slots_portals.id;
CREATE TABLE advertisers (
    id integer NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    due_on_day smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL
);
CREATE SEQUENCE advertisers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE advertisers_id_seq OWNED BY advertisers.id;
CREATE TABLE alerts (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    type_id integer NOT NULL,
    info character varying NOT NULL,
    headline character varying NOT NULL,
    request text,
    reporter_user_id integer,
    reviewer_user_id integer,
    long_version character varying,
    short_version character varying,
    completed_on timestamp without time zone,
    scope integer,
    entity_id integer,
    data character varying
);
CREATE TABLE allowed_competitions_participants (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    participant_id integer NOT NULL
);
CREATE SEQUENCE allowed_competitions_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE allowed_competitions_participants_id_seq OWNED BY allowed_competitions_participants.id;
CREATE TABLE autologin_keys (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    key character varying(40),
    user_id integer NOT NULL,
    lastused_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE autologin_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE autologin_keys_id_seq OWNED BY autologin_keys.id;
CREATE TABLE avatars (
    id integer NOT NULL,
    name character varying NOT NULL,
    level integer DEFAULT (-1) NOT NULL,
    path character varying,
    faction_id integer,
    user_id integer,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    submitter_user_id integer NOT NULL
);
CREATE SEQUENCE avatars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE avatars_id_seq OWNED BY avatars.id;
CREATE TABLE babes (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL
);
CREATE SEQUENCE babes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE babes_id_seq OWNED BY babes.id;
CREATE TABLE ban_requests (
    id integer NOT NULL,
    user_id integer NOT NULL,
    banned_user_id integer NOT NULL,
    confirming_user_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    confirmed_on timestamp without time zone,
    reason character varying NOT NULL,
    unban_user_id integer,
    unban_confirming_user_id integer,
    reason_unban character varying,
    unban_created_on timestamp without time zone,
    unban_confirmed_on timestamp without time zone
);
CREATE SEQUENCE ban_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ban_requests_id_seq OWNED BY ban_requests.id;
CREATE TABLE bazar_districts (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    icon character varying,
    building_top character varying,
    building_middle character varying,
    building_bottom character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE bazar_districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bazar_districts_id_seq OWNED BY bazar_districts.id;
CREATE TABLE bets (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    title character varying NOT NULL,
    description character varying,
    closes_on timestamp without time zone NOT NULL,
    total_ammount numeric(14,2) DEFAULT 0 NOT NULL,
    winning_bets_option_id integer,
    cancelled boolean DEFAULT false NOT NULL,
    forfeit boolean DEFAULT false NOT NULL,
    tie boolean DEFAULT false NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE TABLE bets_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    bets_count integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE bets_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bets_categories_id_seq OWNED BY bets_categories.id;
CREATE SEQUENCE bets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bets_id_seq OWNED BY bets.id;
CREATE TABLE bets_options (
    id integer NOT NULL,
    bet_id integer NOT NULL,
    name character varying NOT NULL,
    ammount numeric(14,2)
);
CREATE SEQUENCE bets_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bets_options_id_seq OWNED BY bets_options.id;
CREATE TABLE bets_tickets (
    id integer NOT NULL,
    bets_option_id integer NOT NULL,
    user_id integer NOT NULL,
    ammount numeric(14,2),
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE bets_tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bets_tickets_id_seq OWNED BY bets_tickets.id;
CREATE TABLE blogentries (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    title character varying NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    log character varying,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE SEQUENCE blogentries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE blogentries_id_seq OWNED BY blogentries.id;
CREATE TABLE cash_movements (
    id integer NOT NULL,
    description character varying NOT NULL,
    object_id_from integer,
    object_id_to integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ammount numeric(14,2),
    object_id_from_class character varying,
    object_id_to_class character varying
);
CREATE SEQUENCE cash_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE cash_movements_id_seq OWNED BY cash_movements.id;
SET default_with_oids = true;
CREATE TABLE chatlines (
    id integer NOT NULL,
    line character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    sent_to_irc boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE chatlines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE chatlines_id_seq OWNED BY chatlines.id;
CREATE TABLE clans (
    id integer NOT NULL,
    name character varying NOT NULL,
    tag character varying NOT NULL,
    simple_mode boolean DEFAULT true NOT NULL,
    website_external character varying,
    created_on timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    irc_channel character varying,
    irc_server character varying,
    o3_websites_dynamicwebsite_id integer,
    logo character varying,
    description text,
    competition_roster character varying,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    members_count integer DEFAULT 0 NOT NULL,
    website_activated boolean DEFAULT false NOT NULL,
    creator_user_id integer,
    cache_popularity integer,
    ranking_popularity_pos integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE clans_friends (
    from_clan_id integer NOT NULL,
    from_wants boolean DEFAULT false NOT NULL,
    to_clan_id integer NOT NULL,
    to_wants boolean DEFAULT false NOT NULL,
    id integer NOT NULL
);
CREATE SEQUENCE clans_friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_friends_id_seq OWNED BY clans_friends.id;
CREATE TABLE clans_games (
    clan_id integer NOT NULL,
    game_id integer NOT NULL
);
CREATE TABLE clans_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    clans_groups_type_id integer NOT NULL,
    clan_id integer
);
CREATE SEQUENCE clans_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_groups_id_seq OWNED BY clans_groups.id;
CREATE TABLE clans_groups_types (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE clans_groups_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_groups_types_id_seq OWNED BY clans_groups_types.id;
CREATE TABLE clans_groups_users (
    clans_group_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE SEQUENCE clans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_id_seq OWNED BY clans.id;
SET default_with_oids = false;
CREATE TABLE clans_logs_entries (
    id integer NOT NULL,
    message character varying,
    clan_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE clans_logs_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_logs_entries_id_seq OWNED BY clans_logs_entries.id;
CREATE TABLE clans_movements (
    id integer NOT NULL,
    clan_id integer NOT NULL,
    user_id integer,
    direction smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE clans_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_movements_id_seq OWNED BY clans_movements.id;
SET default_with_oids = true;
CREATE TABLE clans_sponsors (
    id integer NOT NULL,
    name character varying NOT NULL,
    clan_id integer NOT NULL,
    url character varying,
    image character varying
);
CREATE SEQUENCE clans_sponsors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_sponsors_id_seq OWNED BY clans_sponsors.id;
SET default_with_oids = false;
CREATE TABLE columns (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);
CREATE TABLE columns_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    columns_count integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE columns_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE columns_categories_id_seq OWNED BY columns_categories.id;
CREATE SEQUENCE columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE columns_id_seq OWNED BY columns.id;
CREATE TABLE comment_violation_opinions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    comment_id integer NOT NULL,
    cls smallint NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE comment_violation_opinions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE comment_violation_opinions_id_seq OWNED BY comment_violation_opinions.id;
CREATE TABLE comments (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    host inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    comment text NOT NULL,
    has_comments_valorations boolean DEFAULT false NOT NULL,
    portal_id integer,
    cache_rating character varying,
    netiquette_violation boolean,
    lastowner_version character varying,
    lastedited_by_user_id integer,
    deleted boolean DEFAULT false NOT NULL,
    random_v numeric DEFAULT random(),
    state smallint DEFAULT 0 NOT NULL,
    moderation_reason smallint,
    karma_points integer
);
CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE comments_id_seq OWNED BY comments.id;
CREATE TABLE comments_valorations (
    id integer NOT NULL,
    comment_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    comments_valorations_type_id integer NOT NULL,
    weight real NOT NULL,
    randval numeric
);
CREATE SEQUENCE comments_valorations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE comments_valorations_id_seq OWNED BY comments_valorations.id;
CREATE TABLE comments_valorations_types (
    id integer NOT NULL,
    name character varying NOT NULL,
    direction smallint NOT NULL
);
CREATE SEQUENCE comments_valorations_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE comments_valorations_types_id_seq OWNED BY comments_valorations_types.id;
CREATE TABLE competitions (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    game_id integer NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    rules text,
    competitions_participants_type_id integer NOT NULL,
    default_maps_per_match smallint,
    forced_maps boolean DEFAULT true NOT NULL,
    random_map_selection_mode smallint,
    scoring_mode smallint DEFAULT 0 NOT NULL,
    pro boolean DEFAULT false NOT NULL,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    force_guids boolean DEFAULT false NOT NULL,
    estimated_end_on timestamp without time zone,
    timetable_for_matches smallint DEFAULT 0 NOT NULL,
    timetable_options character varying,
    fee numeric(14,2),
    invitational boolean DEFAULT false NOT NULL,
    competitions_types_options character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    closed_on timestamp without time zone,
    event_id integer,
    topics_category_id integer,
    header_image character varying,
    type character varying NOT NULL,
    send_notifications boolean DEFAULT true NOT NULL
);
CREATE TABLE competitions_admins (
    competition_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE TABLE competitions_games_maps (
    competition_id integer NOT NULL,
    games_map_id integer NOT NULL
);
CREATE SEQUENCE competitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_id_seq OWNED BY competitions.id;
CREATE TABLE competitions_logs_entries (
    id integer NOT NULL,
    message character varying,
    competition_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE competitions_logs_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_logs_entries_id_seq OWNED BY competitions_logs_entries.id;
CREATE TABLE competitions_matches (
    id integer NOT NULL,
    competition_id integer NOT NULL,
    participant1_id integer,
    participant2_id integer,
    result smallint,
    participant1_confirmed_result boolean DEFAULT false NOT NULL,
    participant2_confirmed_result boolean DEFAULT false NOT NULL,
    admin_confirmed_result boolean DEFAULT false NOT NULL,
    stage smallint DEFAULT 0 NOT NULL,
    maps smallint,
    score_participant1 integer,
    score_participant2 integer,
    accepted boolean DEFAULT true NOT NULL,
    completed_on timestamp without time zone,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    play_on timestamp without time zone,
    event_id integer,
    forfeit_participant1 boolean DEFAULT false NOT NULL,
    forfeit_participant2 boolean DEFAULT false NOT NULL,
    servers character varying,
    ladder_rules character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE TABLE competitions_matches_clans_players (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    competitions_participant_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE competitions_matches_clans_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_matches_clans_players_id_seq OWNED BY competitions_matches_clans_players.id;
CREATE TABLE competitions_matches_games_maps (
    competitions_match_id integer NOT NULL,
    games_map_id integer NOT NULL,
    partial_participant1_score integer,
    partial_participant2_score integer,
    id integer NOT NULL
);
CREATE SEQUENCE competitions_matches_games_maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_matches_games_maps_id_seq OWNED BY competitions_matches_games_maps.id;
CREATE SEQUENCE competitions_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_matches_id_seq OWNED BY competitions_matches.id;
CREATE TABLE competitions_matches_reports (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    user_id integer NOT NULL,
    report text NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE competitions_matches_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_matches_reports_id_seq OWNED BY competitions_matches_reports.id;
CREATE TABLE competitions_matches_uploads (
    id integer NOT NULL,
    competitions_match_id integer NOT NULL,
    user_id integer NOT NULL,
    file character varying,
    description character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE competitions_matches_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_matches_uploads_id_seq OWNED BY competitions_matches_uploads.id;
CREATE TABLE competitions_participants (
    competition_id integer NOT NULL,
    participant_id integer NOT NULL,
    competitions_participants_type_id smallint NOT NULL,
    id integer NOT NULL,
    name character varying NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    ties integer DEFAULT 0 NOT NULL,
    roster character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    points integer,
    "position" integer DEFAULT (random() * (100000)::double precision) NOT NULL
);
CREATE SEQUENCE competitions_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_participants_id_seq OWNED BY competitions_participants.id;
CREATE TABLE competitions_participants_types (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE competitions_participants_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_participants_types_id_seq OWNED BY competitions_participants_types.id;
CREATE TABLE competitions_sponsors (
    id integer NOT NULL,
    name character varying NOT NULL,
    competition_id integer NOT NULL,
    url character varying,
    image character varying
);
CREATE SEQUENCE competitions_sponsors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE competitions_sponsors_id_seq OWNED BY competitions_sponsors.id;
CREATE TABLE competitions_supervisors (
    competition_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE TABLE content_ratings (
    id integer NOT NULL,
    user_id integer,
    ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    rating smallint NOT NULL
);
CREATE SEQUENCE content_ratings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE content_ratings_id_seq OWNED BY content_ratings.id;
CREATE TABLE content_types (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE content_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE content_types_id_seq OWNED BY content_types.id;
CREATE TABLE contents (
    id integer NOT NULL,
    content_type_id integer NOT NULL,
    external_id integer NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    name character varying NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    game_id integer,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    gaming_platform_id integer,
    url character varying,
    user_id integer NOT NULL,
    portal_id integer,
    bazar_district_id integer,
    closed boolean DEFAULT false NOT NULL,
    source character varying,
    karma_points integer
);
CREATE SEQUENCE contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE contents_id_seq OWNED BY contents.id;
CREATE TABLE contents_locks (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE SEQUENCE contents_locks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE contents_locks_id_seq OWNED BY contents_locks.id;
CREATE TABLE contents_recommendations (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    sender_user_id integer NOT NULL,
    receiver_user_id integer NOT NULL,
    content_id integer NOT NULL,
    seen_on timestamp without time zone,
    marked_as_bad boolean DEFAULT false NOT NULL,
    confidence double precision,
    expected_rating smallint,
    comment character varying
);
CREATE SEQUENCE contents_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE contents_recommendations_id_seq OWNED BY contents_recommendations.id;
CREATE TABLE contents_terms (
    id integer NOT NULL,
    content_id integer NOT NULL,
    term_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE contents_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE contents_terms_id_seq OWNED BY contents_terms.id;
CREATE TABLE contents_versions (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    content_id integer NOT NULL,
    data text
);
CREATE SEQUENCE contents_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE contents_versions_id_seq OWNED BY contents_versions.id;
CREATE TABLE countries (
    id integer NOT NULL,
    code character varying,
    name character varying
);
CREATE TABLE coverages (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    description text NOT NULL,
    main text,
    event_id integer NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE TABLE decision_choices (
    id integer NOT NULL,
    decision_id integer NOT NULL,
    name character varying
);
CREATE SEQUENCE decision_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE decision_choices_id_seq OWNED BY decision_choices.id;
CREATE TABLE decision_comments (
    id integer NOT NULL,
    decision_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    comment character varying
);
CREATE SEQUENCE decision_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE decision_comments_id_seq OWNED BY decision_comments.id;
CREATE TABLE decision_user_choices (
    id integer NOT NULL,
    decision_id integer NOT NULL,
    user_id integer NOT NULL,
    decision_choice_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    probability_right double precision NOT NULL,
    custom_reason character varying,
    canned_reason_id character varying
);
CREATE SEQUENCE decision_user_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE decision_user_choices_id_seq OWNED BY decision_user_choices.id;
CREATE TABLE decision_user_reputations (
    id integer NOT NULL,
    decision_type_class character varying NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    probability_right double precision NOT NULL,
    all_time_right_choices integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE decision_user_reputations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE decision_user_reputations_id_seq OWNED BY decision_user_reputations.id;
CREATE TABLE decisions (
    id integer NOT NULL,
    decision_type_class character varying NOT NULL,
    choice_type_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    state integer NOT NULL,
    min_user_choices integer NOT NULL,
    context text,
    final_decision_choice_id integer
);
CREATE SEQUENCE decisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE decisions_id_seq OWNED BY decisions.id;
CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    queue character varying
);
CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;
CREATE TABLE demo_mirrors (
    id integer NOT NULL,
    demo_id integer NOT NULL,
    url character varying NOT NULL
);
CREATE SEQUENCE demo_mirrors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE demo_mirrors_id_seq OWNED BY demo_mirrors.id;
CREATE TABLE demos (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    title character varying NOT NULL,
    description character varying,
    entity1_local_id integer,
    entity2_local_id integer,
    entity1_external character varying,
    entity2_external character varying,
    games_map_id integer,
    event_id integer,
    pov_type smallint,
    pov_entity smallint,
    file character varying,
    file_hash_md5 character varying,
    downloaded_times integer DEFAULT 0 NOT NULL,
    file_size bigint,
    games_mode_id integer,
    games_version_id integer,
    demotype smallint,
    played_on date,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE TABLE demos_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    demos_count integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE demos_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE demos_categories_id_seq OWNED BY demos_categories.id;
CREATE SEQUENCE demos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE demos_id_seq OWNED BY demos.id;
CREATE TABLE dictionary_words (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying NOT NULL,
    pos_type integer
);
CREATE SEQUENCE dictionary_words_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE dictionary_words_id_seq OWNED BY dictionary_words.id;
CREATE TABLE download_mirrors (
    id integer NOT NULL,
    download_id integer NOT NULL,
    url character varying NOT NULL
);
CREATE SEQUENCE download_mirrors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE download_mirrors_id_seq OWNED BY download_mirrors.id;
CREATE TABLE downloaded_downloads (
    id integer NOT NULL,
    download_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ip inet NOT NULL,
    session_id character varying,
    referer character varying,
    user_id integer,
    download_cookie character varying(32)
);
CREATE SEQUENCE downloaded_downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE downloaded_downloads_id_seq OWNED BY downloaded_downloads.id;
CREATE TABLE downloads (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    file character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    essential boolean DEFAULT false NOT NULL,
    downloaded_times integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    file_hash_md5 character(32),
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE TABLE downloads_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    downloads_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    clan_id integer
);
CREATE SEQUENCE downloads_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE downloads_categories_id_seq OWNED BY downloads_categories.id;
CREATE SEQUENCE downloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE downloads_id_seq OWNED BY downloads.id;
CREATE TABLE dudes (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL
);
CREATE SEQUENCE dudes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE dudes_id_seq OWNED BY dudes.id;
CREATE TABLE events (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    description text,
    starts_on timestamp without time zone NOT NULL,
    ends_on timestamp without time zone NOT NULL,
    website character varying,
    parent_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    deleted boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE TABLE events_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    events_count integer DEFAULT 0 NOT NULL,
    clan_id integer
);
CREATE SEQUENCE events_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE events_categories_id_seq OWNED BY events_categories.id;
CREATE SEQUENCE events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE events_id_seq OWNED BY events.id;
CREATE SEQUENCE events_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE events_news_id_seq OWNED BY coverages.id;
CREATE TABLE events_users (
    event_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE VIEW f AS
    SELECT count(comments.id) AS count FROM comments GROUP BY date_trunc('day'::text, comments.created_on) ORDER BY date_trunc('day'::text, comments.created_on) DESC OFFSET 1 LIMIT 360;
CREATE TABLE factions (
    id integer NOT NULL,
    name character varying NOT NULL,
    building_bottom character varying,
    building_top character varying,
    building_middle character varying,
    description character varying,
    why_join character varying,
    code character varying,
    members_count integer DEFAULT 0 NOT NULL,
    cash numeric(14,2) DEFAULT 0 NOT NULL,
    is_gaming_platform boolean DEFAULT false NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    cache_member_cohesion numeric
);
CREATE TABLE factions_banned_users (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying,
    banner_user_id integer NOT NULL
);
CREATE SEQUENCE factions_banned_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_banned_users_id_seq OWNED BY factions_banned_users.id;
CREATE TABLE factions_capos (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE SEQUENCE factions_capos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_capos_id_seq OWNED BY factions_capos.id;
CREATE TABLE factions_editors (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    user_id integer NOT NULL,
    content_type_id integer NOT NULL
);
CREATE SEQUENCE factions_editors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_editors_id_seq OWNED BY factions_editors.id;
CREATE TABLE factions_headers (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    name character varying NOT NULL,
    lasttime_used_on timestamp without time zone
);
CREATE SEQUENCE factions_headers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_headers_id_seq OWNED BY factions_headers.id;
CREATE SEQUENCE factions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_id_seq OWNED BY factions.id;
CREATE TABLE factions_links (
    id integer NOT NULL,
    faction_id integer NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    image character varying
);
CREATE SEQUENCE factions_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_links_id_seq OWNED BY factions_links.id;
CREATE TABLE factions_portals (
    faction_id integer NOT NULL,
    portal_id integer NOT NULL,
    id integer NOT NULL
);
CREATE SEQUENCE factions_portals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE factions_portals_id_seq OWNED BY factions_portals.id;
SET default_with_oids = true;
CREATE TABLE faq_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    "position" integer,
    parent_id integer,
    root_id integer
);
CREATE SEQUENCE faq_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE faq_categories_id_seq OWNED BY faq_categories.id;
CREATE TABLE faq_entries (
    id integer NOT NULL,
    question character varying NOT NULL,
    answer character varying NOT NULL,
    faq_category_id integer NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    "position" integer
);
CREATE SEQUENCE faq_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE faq_entries_id_seq OWNED BY faq_entries.id;
SET default_with_oids = false;
CREATE TABLE topics_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    forum_category_id integer,
    topics_count integer DEFAULT 0 NOT NULL,
    updated_on timestamp without time zone,
    parent_id integer,
    description character varying,
    root_id integer,
    code character varying,
    last_topic_id integer,
    comments_count integer DEFAULT 0,
    last_updated_item_id integer,
    avg_popularity double precision,
    clan_id integer,
    nohome boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE forum_forums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE forum_forums_id_seq OWNED BY topics_categories.id;
CREATE TABLE topics (
    id integer NOT NULL,
    title character varying NOT NULL,
    main text NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    sticky boolean DEFAULT false NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    moved_on timestamp without time zone,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    unique_content_id integer
);
CREATE SEQUENCE forum_topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE forum_topics_id_seq OWNED BY topics.id;
CREATE TABLE friends_recommendations (
    id integer NOT NULL,
    user_id integer NOT NULL,
    recommended_user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone,
    added_as_friend boolean,
    reason character varying
);
CREATE SEQUENCE friends_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE friends_recommendations_id_seq OWNED BY friends_recommendations.id;
SET default_with_oids = true;
CREATE TABLE friendships (
    sender_user_id integer NOT NULL,
    receiver_user_id integer,
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    accepted_on timestamp without time zone,
    receiver_email character varying,
    invitation_text character varying,
    external_invitation_key character(32)
);
CREATE SEQUENCE friends_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE friends_users_id_seq OWNED BY friendships.id;
SET default_with_oids = false;
CREATE TABLE funthings (
    id integer NOT NULL,
    title character varying NOT NULL,
    description character varying,
    main character varying,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE SEQUENCE funthings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE funthings_id_seq OWNED BY funthings.id;
CREATE TABLE gamersmafiageist_codes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    code character varying,
    survey_edition_date date NOT NULL
);
CREATE SEQUENCE gamersmafiageist_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gamersmafiageist_codes_id_seq OWNED BY gamersmafiageist_codes.id;
SET default_with_oids = true;
CREATE TABLE games (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    has_guids boolean DEFAULT false NOT NULL,
    guid_format character varying,
    has_game_maps boolean DEFAULT false NOT NULL,
    has_competitions boolean DEFAULT false NOT NULL,
    has_demos boolean DEFAULT false NOT NULL,
    user_id integer NOT NULL,
    has_faction boolean DEFAULT false NOT NULL,
    gaming_platform_id integer NOT NULL,
    release_date character varying,
    publisher_id integer
);
SET default_with_oids = false;
CREATE TABLE games_gaming_platforms (
    game_id integer NOT NULL,
    gaming_platform_id integer NOT NULL
);
CREATE SEQUENCE games_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE games_id_seq OWNED BY games.id;
CREATE TABLE games_maps (
    id integer NOT NULL,
    name character varying NOT NULL,
    game_id integer NOT NULL,
    download_id integer,
    screenshot character varying
);
CREATE SEQUENCE games_maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE games_maps_id_seq OWNED BY games_maps.id;
CREATE TABLE games_modes (
    id integer NOT NULL,
    name character varying NOT NULL,
    game_id integer NOT NULL,
    entity_type smallint
);
CREATE SEQUENCE games_modes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE games_modes_id_seq OWNED BY games_modes.id;
CREATE TABLE games_users (
    game_id integer NOT NULL,
    user_id integer NOT NULL
);
CREATE TABLE games_versions (
    id integer NOT NULL,
    version character varying NOT NULL,
    game_id integer NOT NULL
);
CREATE SEQUENCE games_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE games_versions_id_seq OWNED BY games_versions.id;
CREATE TABLE gaming_platforms (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    has_faction boolean DEFAULT false NOT NULL
);
CREATE TABLE gaming_platforms_users (
    user_id integer NOT NULL,
    gaming_platform_id integer NOT NULL
);
CREATE TABLE global_vars (
    id integer NOT NULL,
    online_anonymous integer DEFAULT 0 NOT NULL,
    online_registered integer DEFAULT 0 NOT NULL,
    svn_revision character varying,
    ads_slots_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    gmtv_channels_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    portals_updated_on timestamp without time zone DEFAULT now() NOT NULL,
    max_cache_valorations_weights_on_self_comments numeric,
    clans_updated_on timestamp without time zone,
    last_comment_on timestamp without time zone
);
CREATE SEQUENCE global_vars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE global_vars_id_seq OWNED BY global_vars.id;
CREATE TABLE gmtv_broadcast_messages (
    id integer NOT NULL,
    message character varying NOT NULL,
    starts_on timestamp without time zone DEFAULT now() NOT NULL,
    ends_on timestamp without time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL
);
CREATE SEQUENCE gmtv_broadcast_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gmtv_broadcast_messages_id_seq OWNED BY gmtv_broadcast_messages.id;
CREATE TABLE gmtv_channels (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    faction_id integer,
    file character varying,
    screenshot character varying
);
CREATE SEQUENCE gmtv_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gmtv_channels_id_seq OWNED BY gmtv_channels.id;
CREATE SEQUENCE goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description character varying,
    owner_user_id integer
);
CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE groups_id_seq OWNED BY groups.id;
CREATE TABLE groups_messages (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    title character varying,
    main character varying,
    parent_id integer,
    root_id integer,
    user_id integer
);
CREATE SEQUENCE groups_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE groups_messages_id_seq OWNED BY groups_messages.id;
CREATE TABLE images (
    id integer NOT NULL,
    description character varying,
    file character varying,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    file_hash_md5 character(32),
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE TABLE images_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    images_count integer DEFAULT 0 NOT NULL,
    clan_id integer
);
CREATE SEQUENCE images_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE images_categories_id_seq OWNED BY images_categories.id;
CREATE SEQUENCE images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE images_id_seq OWNED BY images.id;
CREATE TABLE interviews (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);
CREATE TABLE interviews_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    interviews_count integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE interviews_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE interviews_categories_id_seq OWNED BY interviews_categories.id;
CREATE SEQUENCE interviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE interviews_id_seq OWNED BY interviews.id;
CREATE TABLE ip_bans (
    id integer NOT NULL,
    ip inet NOT NULL,
    created_on timestamp without time zone NOT NULL,
    expires_on timestamp without time zone,
    comment character varying,
    user_id integer
);
CREATE SEQUENCE ip_bans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ip_bans_id_seq OWNED BY ip_bans.id;
CREATE TABLE ip_passwords_resets_requests (
    id integer NOT NULL,
    ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE ip_passwords_resets_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ip_passwords_resets_requests_id_seq OWNED BY ip_passwords_resets_requests.id;
CREATE TABLE macropolls (
    poll_id integer NOT NULL,
    user_id integer,
    answers text,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ipaddr inet DEFAULT '0.0.0.0'::inet NOT NULL,
    host character varying,
    id integer NOT NULL
);
CREATE TABLE macropolls_2007_1 (
    id integer NOT NULL,
    lacantidaddecontenidosquesepublicanenlawebteparece character varying,
    __sabesquepuedesenviarcontenidos_ character varying,
    __sabesquepuedesdecidirsiuncontenidosepublicaono_ character varying,
    __echasenfaltafuncionesimportantesenlaweb_ character varying,
    __estassuscritoafeedsrss_ character varying,
    participasencompeticiones_clanbase character varying,
    __tegustaelmanga_anime_ character varying,
    larapidezdecargadelaspaginasteparece character varying,
    lasecciondeforosteparece character varying,
    tesientesidentificadoconlaweb character varying,
    prefeririasnovermasqueloscontenidosdetujuego character varying,
    __quecreesquedeberiamosmejorardeformamasurgenteenlaweb_ character varying,
    ellogodelawebtegusta character varying,
    __estasenalgunclan_ character varying,
    eldisenodelawebteparece character varying,
    elnumerodefuncionesdelawebteparece_bis_ character varying,
    laactituddelosadministradores_bossesymoderadoresdelawebteparece character varying,
    __tienesalgunavideoconsola_ character varying,
    siofreciesemosdenuevoelsistemadewebsparaclanes___creesquetuclan character varying,
    sipudiesesleregalariasalwebmasterunbilletea character varying,
    elambienteenloscomentarioses character varying,
    elnumerodefuncionesdelawebteparece character varying,
    seguneltiempoquelededicasalosjuegosteconsiderasunjugador character varying,
    lacantidaddepublicidadqueapareceenlawebteparece character varying,
    lalabordelosadministradores_bossesymoderadoresdelawebteparece character varying,
    __sabesquepuedescreartuspropiascompeticionesoparticiparencompet character varying,
    lascabecerasteparecen character varying,
    tuopiniongeneralsobrelawebes character varying,
    razonprincipalporlaquevisitaslaweb character varying,
    lacalidaddeloscontenidosteparece character varying,
    lasecciondebabes_dudestegusta character varying,
    __quetendriaquetenerlawebparaquefueseperfectaparati_ character varying,
    __deentrelaswebsdejuegosquevisitasfrecuentementedondenossituari character varying,
    user_id integer,
    created_on character varying NOT NULL,
    ipaddr inet NOT NULL,
    host character varying
);
CREATE SEQUENCE macropolls_2007_1_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE macropolls_2007_1_id_seq OWNED BY macropolls_2007_1.id;
CREATE SEQUENCE macropolls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE macropolls_id_seq OWNED BY macropolls.id;
SET default_with_oids = true;
CREATE TABLE messages (
    id integer NOT NULL,
    user_id_from integer NOT NULL,
    user_id_to integer NOT NULL,
    title character varying NOT NULL,
    message text NOT NULL,
    created_on timestamp without time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    in_reply_to integer,
    has_replies boolean DEFAULT false NOT NULL,
    message_type smallint DEFAULT 0 NOT NULL,
    sender_deleted boolean DEFAULT false NOT NULL,
    receiver_deleted boolean DEFAULT false NOT NULL,
    thread_id integer
);
CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE messages_id_seq OWNED BY messages.id;
SET default_with_oids = false;
CREATE TABLE ne_references (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    referenced_on timestamp without time zone NOT NULL,
    entity_class character varying NOT NULL,
    entity_id integer NOT NULL,
    referencer_class character varying NOT NULL,
    referencer_id integer NOT NULL
);
CREATE SEQUENCE ne_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ne_references_id_seq OWNED BY ne_references.id;
CREATE TABLE news (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text,
    approved_by_user_id integer,
    hits_registered integer DEFAULT 0 NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);
CREATE TABLE news_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    news_count integer DEFAULT 0 NOT NULL,
    clan_id integer,
    file character varying
);
CREATE SEQUENCE news_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE news_categories_id_seq OWNED BY news_categories.id;
CREATE SEQUENCE news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE news_id_seq OWNED BY news.id;
CREATE TABLE notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description character varying,
    read_on timestamp without time zone,
    sender_user_id integer NOT NULL,
    type_id integer NOT NULL,
    data character varying
);
CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;
CREATE TABLE outstanding_entities (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    portal_id integer,
    active_on date NOT NULL,
    type character varying NOT NULL,
    reason character varying
);
CREATE SEQUENCE outstanding_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE outstanding_users_id_seq OWNED BY outstanding_entities.id;
CREATE SEQUENCE platforms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE platforms_id_seq OWNED BY gaming_platforms.id;
CREATE TABLE polls (
    id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    starts_on timestamp without time zone NOT NULL,
    ends_on timestamp without time zone NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    clan_id integer,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    polls_votes_count integer DEFAULT 0 NOT NULL
);
CREATE TABLE polls_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    description character varying,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    root_id integer,
    code character varying,
    polls_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    clan_id integer
);
CREATE SEQUENCE polls_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE polls_categories_id_seq OWNED BY polls_categories.id;
CREATE SEQUENCE polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE polls_id_seq OWNED BY polls.id;
CREATE TABLE polls_options (
    id integer NOT NULL,
    poll_id integer NOT NULL,
    name character varying NOT NULL,
    polls_votes_count integer DEFAULT 0 NOT NULL,
    "position" integer
);
CREATE SEQUENCE polls_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE polls_options_id_seq OWNED BY polls_options.id;
CREATE TABLE polls_votes (
    polls_option_id integer NOT NULL,
    user_id integer,
    id integer NOT NULL,
    remote_ip inet NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE polls_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE polls_votes_id_seq OWNED BY polls_votes.id;
CREATE TABLE portal_headers (
    id integer NOT NULL,
    date timestamp without time zone NOT NULL,
    factions_header_id integer NOT NULL,
    portal_id integer NOT NULL
);
CREATE SEQUENCE portal_headers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE portal_headers_id_seq OWNED BY portal_headers.id;
CREATE TABLE portal_hits (
    portal_id integer,
    date date DEFAULT (now())::date NOT NULL,
    hits integer DEFAULT 0 NOT NULL,
    id integer NOT NULL
);
CREATE SEQUENCE portal_hits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE portal_hits_id_seq OWNED BY portal_hits.id;
CREATE TABLE portals (
    id integer NOT NULL,
    name character varying NOT NULL,
    code character varying NOT NULL,
    type character varying DEFAULT 'FactionsPortal'::character varying NOT NULL,
    fqdn character varying,
    options character varying,
    clan_id integer,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    skin_id integer,
    default_gmtv_channel_id integer,
    cache_recent_hits_count integer,
    factions_portal_home character varying,
    small_header character varying,
    last_comment_on timestamp without time zone
);
CREATE SEQUENCE portals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE portals_id_seq OWNED BY portals.id;
CREATE TABLE portals_skins (
    portal_id integer NOT NULL,
    skin_id integer NOT NULL
);
CREATE TABLE potds (
    id integer NOT NULL,
    date date NOT NULL,
    image_id integer NOT NULL,
    portal_id integer,
    images_category_id integer,
    term_id integer
);
CREATE SEQUENCE potds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE potds_id_seq OWNED BY potds.id;
CREATE TABLE products (
    id integer NOT NULL,
    name character varying NOT NULL,
    price numeric(14,2) NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    description text,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    cls character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL
);
CREATE SEQUENCE products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE products_id_seq OWNED BY products.id;
CREATE TABLE profile_signatures (
    id integer NOT NULL,
    user_id integer NOT NULL,
    signer_user_id integer NOT NULL,
    signature character varying NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE profile_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE profile_signatures_id_seq OWNED BY profile_signatures.id;
CREATE TABLE questions (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    accepted_answer_comment_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    approved_by_user_id integer,
    ammount numeric(10,2),
    answered_on timestamp without time zone,
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    answer_selected_by_user_id integer
);
CREATE TABLE questions_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    forum_category_id integer,
    questions_count integer DEFAULT 0 NOT NULL,
    updated_on timestamp without time zone,
    parent_id integer,
    description character varying,
    root_id integer,
    code character varying,
    last_question_id integer,
    comments_count integer DEFAULT 0,
    last_updated_item_id integer,
    avg_popularity double precision,
    clan_id integer,
    nohome boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE questions_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE questions_categories_id_seq OWNED BY questions_categories.id;
CREATE SEQUENCE questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE questions_id_seq OWNED BY questions.id;
CREATE TABLE recruitment_ads (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    clan_id integer,
    game_id integer NOT NULL,
    levels character varying,
    country_id integer,
    main text,
    deleted boolean DEFAULT false NOT NULL,
    title character varying NOT NULL,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer
);
CREATE SEQUENCE recruitment_ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE recruitment_ads_id_seq OWNED BY recruitment_ads.id;
CREATE TABLE refered_hits (
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ipaddr inet NOT NULL,
    referer character varying NOT NULL,
    id integer NOT NULL
);
CREATE SEQUENCE refered_hits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE refered_hits_id_seq OWNED BY refered_hits.id;
CREATE TABLE reviews (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    home_image character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);
CREATE TABLE reviews_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    reviews_count integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE reviews_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE reviews_categories_id_seq OWNED BY reviews_categories.id;
CREATE SEQUENCE reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE reviews_id_seq OWNED BY reviews.id;
CREATE TABLE schema_migrations (
    version character varying NOT NULL
);
CREATE TABLE sent_emails (
    id integer NOT NULL,
    message_key character varying NOT NULL,
    title character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    first_read_on timestamp without time zone,
    sender character varying,
    recipient character varying,
    recipient_user_id integer
);
CREATE SEQUENCE sent_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE sent_emails_id_seq OWNED BY sent_emails.id;
CREATE TABLE silenced_emails (
    id integer NOT NULL,
    email character varying NOT NULL
);
CREATE SEQUENCE silenced_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE silenced_emails_id_seq OWNED BY silenced_emails.id;
CREATE TABLE skins (
    id integer NOT NULL,
    name character varying NOT NULL,
    hid character varying NOT NULL,
    user_id integer NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    file character varying,
    version integer DEFAULT 0 NOT NULL,
    skin_variables text
);
CREATE TABLE skins_files (
    id integer NOT NULL,
    skin_id integer NOT NULL,
    file character varying NOT NULL
);
CREATE SEQUENCE skins_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE skins_files_id_seq OWNED BY skins_files.id;
CREATE SEQUENCE skins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE skins_id_seq OWNED BY skins.id;
CREATE SEQUENCE slog_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE slog_entries_id_seq OWNED BY alerts.id;
CREATE TABLE sold_products (
    id integer NOT NULL,
    product_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    price_paid numeric(14,2) NOT NULL,
    used boolean DEFAULT false NOT NULL,
    type character varying
);
CREATE SEQUENCE sold_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE sold_products_id_seq OWNED BY sold_products.id;
CREATE TABLE staff_candidate_votes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    staff_candidate_id integer NOT NULL,
    staff_position_id integer NOT NULL
);
CREATE SEQUENCE staff_candidate_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE staff_candidate_votes_id_seq OWNED BY staff_candidate_votes.id;
CREATE TABLE staff_candidates (
    id integer NOT NULL,
    staff_position_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    key_result1 character varying,
    key_result2 character varying,
    key_result3 character varying,
    is_winner boolean DEFAULT false NOT NULL,
    term_starts_on date NOT NULL,
    term_ends_on date NOT NULL,
    is_denied boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE staff_candidates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE staff_candidates_id_seq OWNED BY staff_candidates.id;
CREATE TABLE staff_positions (
    id integer NOT NULL,
    staff_type_id integer NOT NULL,
    state character varying DEFAULT 'unassigned'::character varying NOT NULL,
    term_starts_on date,
    term_ends_on date,
    staff_candidate_id integer,
    slots smallint DEFAULT 1 NOT NULL
);
CREATE SEQUENCE staff_positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE staff_positions_id_seq OWNED BY staff_positions.id;
CREATE TABLE staff_types (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE staff_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE staff_types_id_seq OWNED BY staff_types.id;
CREATE TABLE terms (
    id integer NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description character varying,
    parent_id integer,
    game_id integer,
    gaming_platform_id integer,
    bazar_district_id integer,
    clan_id integer,
    contents_count integer DEFAULT 0 NOT NULL,
    last_updated_item_id integer,
    comments_count integer DEFAULT 0 NOT NULL,
    root_id integer,
    taxonomy character varying NOT NULL,
    short_description character varying,
    long_description text,
    header_image character varying,
    square_image character varying
);
CREATE SEQUENCE terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE terms_id_seq OWNED BY terms.id;
SET default_with_oids = true;
CREATE TABLE tracker_items (
    id integer NOT NULL,
    content_id integer NOT NULL,
    user_id integer NOT NULL,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    is_tracked boolean DEFAULT false NOT NULL,
    notification_sent_on timestamp without time zone
);
CREATE SEQUENCE tracker_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE tracker_items_id_seq OWNED BY tracker_items.id;
SET default_with_oids = false;
CREATE TABLE training_questions (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer,
    type character varying NOT NULL,
    _ner_annotate_comment_main text,
    _ner_annotate_comment_main_annotated text,
    _ner_annotate_comment_comment_id integer
);
CREATE SEQUENCE treated_visitors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE TABLE treated_visitors (
    id integer DEFAULT nextval('treated_visitors_id_seq'::regclass) NOT NULL,
    ab_test_id integer NOT NULL,
    visitor_id character varying NOT NULL,
    treatment integer NOT NULL,
    user_id integer
);
CREATE TABLE tutorials (
    id integer NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    main text NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL,
    approved_by_user_id integer,
    hits_anonymous integer DEFAULT 0 NOT NULL,
    hits_registered integer DEFAULT 0 NOT NULL,
    home_image character varying,
    cache_rating smallint,
    cache_rated_times smallint,
    cache_comments_count integer DEFAULT 0 NOT NULL,
    log character varying,
    state smallint DEFAULT 0 NOT NULL,
    cache_weighted_rank numeric(10,2),
    closed boolean DEFAULT false NOT NULL,
    unique_content_id integer,
    source character varying
);
CREATE TABLE tutorials_categories (
    id integer NOT NULL,
    name character varying NOT NULL,
    parent_id integer,
    root_id integer,
    code character varying,
    description character varying,
    last_updated_item_id integer,
    tutorials_count integer DEFAULT 0
);
CREATE SEQUENCE tutorials_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE tutorials_categories_id_seq OWNED BY tutorials_categories.id;
CREATE SEQUENCE tutorials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE tutorials_id_seq OWNED BY tutorials.id;
CREATE TABLE user_interests (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    entity_type_class character varying NOT NULL,
    entity_id integer NOT NULL,
    show_in_menu boolean DEFAULT true NOT NULL,
    menu_shortcut character varying NOT NULL
);
CREATE SEQUENCE user_interests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE user_interests_id_seq OWNED BY user_interests.id;
CREATE TABLE user_login_changes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    old_login character varying NOT NULL
);
CREATE SEQUENCE user_login_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE user_login_changes_id_seq OWNED BY user_login_changes.id;
CREATE TABLE users (
    id integer NOT NULL,
    login character varying(80),
    password character varying(40),
    validkey character varying(40),
    email character varying(100) DEFAULT ''::character varying NOT NULL,
    newemail character varying(100),
    ipaddr character varying(15) DEFAULT ''::character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    firstname character varying DEFAULT ''::character varying,
    lastname character varying DEFAULT ''::character varying,
    image bytea,
    lastseen_on timestamp without time zone DEFAULT now() NOT NULL,
    faction_id integer,
    faction_last_changed_on timestamp without time zone,
    avatar_id integer,
    city character varying,
    homepage character varying,
    sex smallint,
    msn character varying,
    icq character varying,
    birthday date,
    cache_karma_points integer,
    irc character varying,
    country_id integer,
    photo character varying,
    hw_mouse character varying,
    hw_processor character varying,
    hw_motherboard character varying,
    hw_ram character varying,
    hw_hdd character varying,
    hw_graphiccard character varying,
    hw_soundcard character varying,
    hw_headphones character varying,
    hw_monitor character varying,
    hw_connection character varying,
    description text,
    comments_count integer DEFAULT 0 NOT NULL,
    referer_user_id integer,
    notifications_global boolean DEFAULT true NOT NULL,
    notifications_newmessages boolean DEFAULT true NOT NULL,
    notifications_newregistrations boolean DEFAULT true NOT NULL,
    notifications_trackerupdates boolean DEFAULT true NOT NULL,
    xfire character varying,
    cache_unread_messages integer DEFAULT 0,
    resurrected_by_user_id integer,
    resurrection_started_on timestamp without time zone,
    using_tracker boolean DEFAULT false NOT NULL,
    secret character(32),
    cash numeric(14,2) DEFAULT 0.00 NOT NULL,
    lastcommented_on timestamp without time zone,
    global_bans integer DEFAULT 0 NOT NULL,
    last_clan_id integer,
    antiflood_level smallint DEFAULT (-1) NOT NULL,
    last_competition_id integer,
    competition_roster character varying,
    enable_competition_indicator boolean DEFAULT false NOT NULL,
    enable_profile_signatures boolean DEFAULT false NOT NULL,
    profile_signatures_count integer DEFAULT 0 NOT NULL,
    wii_code character(16),
    email_public boolean DEFAULT false NOT NULL,
    gamertag character varying,
    googletalk character varying,
    yahoo_im character varying,
    notifications_newprofilesignature boolean DEFAULT true NOT NULL,
    tracker_autodelete_old_contents boolean DEFAULT true NOT NULL,
    comment_adds_to_tracker_enabled boolean DEFAULT true NOT NULL,
    cache_remaining_rating_slots integer,
    has_seen_tour boolean DEFAULT false NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    cache_is_faction_leader boolean DEFAULT false NOT NULL,
    profile_last_updated_on timestamp without time zone,
    visitor_id character varying,
    comments_valorations_type_id integer,
    comments_valorations_strength numeric(10,2),
    enable_comments_sig boolean DEFAULT false NOT NULL,
    comments_sig character varying,
    comment_show_sigs boolean,
    has_new_friend_requests boolean DEFAULT false NOT NULL,
    default_portal character varying,
    emblems_mask character varying,
    random_id double precision DEFAULT random(),
    is_staff boolean DEFAULT false NOT NULL,
    pending_alerts integer DEFAULT 0 NOT NULL,
    ranking_karma_pos integer,
    ranking_popularity_pos integer,
    cache_popularity integer,
    login_is_ne_unfriendly boolean DEFAULT false NOT NULL,
    cache_valorations_weights_on_self_comments numeric,
    default_comments_valorations_weight double precision DEFAULT 1.0 NOT NULL,
    last_karma_skill_points integer DEFAULT 0 NOT NULL,
    has_unread_notifications boolean DEFAULT false NOT NULL,
    pending_decisions boolean DEFAULT false NOT NULL
);
CREATE TABLE users_actions (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    user_id integer,
    type_id integer NOT NULL,
    data character varying,
    object_id integer
);
CREATE SEQUENCE users_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_actions_id_seq OWNED BY users_actions.id;
CREATE TABLE users_contents_tags (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    content_id integer NOT NULL,
    term_id integer NOT NULL,
    original_name character varying NOT NULL
);
CREATE SEQUENCE users_contents_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_contents_tags_id_seq OWNED BY users_contents_tags.id;
CREATE TABLE users_emblems (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT (now())::date NOT NULL,
    user_id integer,
    emblem character varying NOT NULL,
    details character varying
);
CREATE SEQUENCE users_emblems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_emblems_id_seq OWNED BY users_emblems.id;
CREATE TABLE users_guids (
    id integer NOT NULL,
    guid character varying NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying
);
CREATE SEQUENCE users_guids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_guids_id_seq OWNED BY users_guids.id;
CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_id_seq OWNED BY users.id;
CREATE TABLE users_lastseen_ips (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    lastseen_on timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    ip inet NOT NULL
);
CREATE SEQUENCE users_lastseen_ips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_lastseen_ips_id_seq OWNED BY users_lastseen_ips.id;
CREATE TABLE users_newsfeeds (
    id integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    user_id integer,
    summary character varying NOT NULL,
    users_action_id integer
);
CREATE SEQUENCE users_newsfeeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_newsfeeds_id_seq OWNED BY users_newsfeeds.id;
CREATE TABLE users_preferences (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    value character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    updated_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE users_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_preferences_id_seq OWNED BY users_preferences.id;
CREATE TABLE users_skills (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role character varying NOT NULL,
    role_data character varying,
    created_on timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE users_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_roles_id_seq OWNED BY users_skills.id;
SET search_path = stats, pg_catalog;
CREATE TABLE ads (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    referer character varying,
    user_id integer,
    user_agent character varying,
    portal_id integer,
    url character varying NOT NULL,
    element_id character varying,
    ip inet NOT NULL,
    visitor_id character varying,
    session_id character varying
);
CREATE TABLE ads_daily (
    id integer NOT NULL,
    ads_slots_instance_id integer,
    created_on date NOT NULL,
    hits integer NOT NULL,
    ctr double precision NOT NULL,
    pageviews integer NOT NULL
);
CREATE SEQUENCE ads_daily_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ads_daily_id_seq OWNED BY ads_daily.id;
CREATE SEQUENCE ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ads_id_seq OWNED BY ads.id;
CREATE TABLE bandit_treatments (
    id integer NOT NULL,
    behaviour_class character varying NOT NULL,
    abtest_treatment character varying NOT NULL,
    round integer DEFAULT (-1) NOT NULL,
    lever0_reward character varying,
    lever1_reward character varying,
    lever2_reward character varying,
    lever3_reward character varying,
    lever4_reward character varying,
    lever5_reward character varying,
    lever6_reward character varying,
    lever7_reward character varying,
    lever8_reward character varying,
    lever9_reward character varying,
    lever10_reward character varying,
    lever11_reward character varying,
    lever12_reward character varying,
    lever13_reward character varying,
    lever14_reward character varying,
    lever15_reward character varying,
    lever16_reward character varying,
    lever17_reward character varying,
    lever18_reward character varying,
    lever19_reward character varying,
    lever20_reward character varying
);
CREATE SEQUENCE bandit_treatments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bandit_treatments_id_seq OWNED BY bandit_treatments.id;
CREATE TABLE bets_results (
    id integer NOT NULL,
    bet_id integer NOT NULL,
    user_id integer NOT NULL,
    net_ammount numeric(10,2)
);
CREATE SEQUENCE bets_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE bets_results_id_seq OWNED BY bets_results.id;
CREATE TABLE clans_daily_stats (
    id integer NOT NULL,
    clan_id integer,
    created_on date NOT NULL,
    popularity integer
);
CREATE SEQUENCE clans_daily_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE clans_daily_stats_id_seq OWNED BY clans_daily_stats.id;
CREATE TABLE dates (
    date date NOT NULL
);
CREATE TABLE general (
    created_on date DEFAULT (now())::date NOT NULL,
    users_total integer DEFAULT 0 NOT NULL,
    users_confirmed integer DEFAULT 0 NOT NULL,
    users_active integer DEFAULT 0 NOT NULL,
    users_banned integer DEFAULT 0 NOT NULL,
    users_disabled integer DEFAULT 0 NOT NULL,
    karma_diff integer DEFAULT 0.0 NOT NULL,
    cash_diff numeric(10,4) DEFAULT 0 NOT NULL,
    new_comments integer DEFAULT 0 NOT NULL,
    refered_hits integer DEFAULT 0 NOT NULL,
    avg_users_online double precision DEFAULT 0 NOT NULL,
    users_unconfirmed integer DEFAULT 0 NOT NULL,
    users_zombie integer DEFAULT 0 NOT NULL,
    users_resurrected integer DEFAULT 0 NOT NULL,
    users_shadow integer DEFAULT 0 NOT NULL,
    users_deleted integer DEFAULT 0 NOT NULL,
    users_unconfirmed_1w integer DEFAULT 0 NOT NULL,
    users_unconfirmed_2w integer DEFAULT 0 NOT NULL,
    new_clans integer,
    new_closed_topics integer,
    new_clans_portals integer,
    avg_page_render_time real,
    users_generating_karma integer,
    karma_per_user real,
    stddev_page_render_time real,
    active_factions_portals integer,
    completed_competitions_matches integer,
    active_clans_portals integer,
    proxy_errors integer,
    new_factions integer,
    http_401 integer,
    http_500 integer,
    http_404 integer,
    avg_db_queries_per_request double precision,
    stddev_db_queries_per_request double precision,
    requests integer,
    database_size bigint,
    sent_emails integer,
    downloaded_downloads_count integer,
    users_refered_today integer,
    played_bets_participation integer DEFAULT 0 NOT NULL,
    played_bets_crowd_correctly_predicted integer DEFAULT 0 NOT NULL
);
CREATE TABLE pageloadtime (
    controller character varying,
    action character varying,
    "time" numeric(10,2),
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    id integer NOT NULL,
    portal_id integer,
    http_status integer,
    db_queries integer,
    db_rows integer
);
CREATE SEQUENCE pageloadtime_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pageloadtime_id_seq OWNED BY pageloadtime.id;
CREATE TABLE pageviews (
    id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now() NOT NULL,
    ip inet NOT NULL,
    referer character varying,
    controller character varying,
    action character varying,
    medium character varying,
    campaign character varying,
    model_id character varying,
    url character varying,
    visitor_id character varying,
    session_id character varying,
    user_agent character varying,
    user_id integer,
    flash_error character varying,
    abtest_treatment character varying,
    portal_id integer,
    source character varying,
    ads_shown character varying
);
CREATE SEQUENCE pageviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pageviews_id_seq OWNED BY pageviews.id;
CREATE TABLE portals (
    id integer NOT NULL,
    created_on date NOT NULL,
    portal_id integer,
    karma integer NOT NULL,
    pageviews integer,
    visits integer,
    unique_visitors integer,
    unique_visitors_reg integer
);
CREATE SEQUENCE portals_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE portals_stats_id_seq OWNED BY portals.id;
CREATE TABLE users_daily_stats (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on date NOT NULL,
    karma integer,
    popularity integer,
    played_bets_participation integer DEFAULT 0 NOT NULL,
    played_bets_correctly_predicted integer DEFAULT 0 NOT NULL
);
CREATE SEQUENCE users_daily_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_daily_stats_id_seq OWNED BY users_daily_stats.id;
CREATE TABLE users_karma_daily_by_portal (
    id integer NOT NULL,
    user_id integer NOT NULL,
    portal_id integer,
    karma integer,
    created_on date NOT NULL
);
CREATE SEQUENCE users_karma_daily_by_portal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_karma_daily_by_portal_id_seq OWNED BY users_karma_daily_by_portal.id;
SET search_path = public, pg_catalog;
ALTER TABLE ONLY ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);
ALTER TABLE ONLY ads_slots ALTER COLUMN id SET DEFAULT nextval('ads_slots_id_seq'::regclass);
ALTER TABLE ONLY ads_slots_instances ALTER COLUMN id SET DEFAULT nextval('ads_slots_instances_id_seq'::regclass);
ALTER TABLE ONLY ads_slots_portals ALTER COLUMN id SET DEFAULT nextval('ads_slots_portals_id_seq'::regclass);
ALTER TABLE ONLY advertisers ALTER COLUMN id SET DEFAULT nextval('advertisers_id_seq'::regclass);
ALTER TABLE ONLY alerts ALTER COLUMN id SET DEFAULT nextval('slog_entries_id_seq'::regclass);
ALTER TABLE ONLY allowed_competitions_participants ALTER COLUMN id SET DEFAULT nextval('allowed_competitions_participants_id_seq'::regclass);
ALTER TABLE ONLY autologin_keys ALTER COLUMN id SET DEFAULT nextval('autologin_keys_id_seq'::regclass);
ALTER TABLE ONLY avatars ALTER COLUMN id SET DEFAULT nextval('avatars_id_seq'::regclass);
ALTER TABLE ONLY babes ALTER COLUMN id SET DEFAULT nextval('babes_id_seq'::regclass);
ALTER TABLE ONLY ban_requests ALTER COLUMN id SET DEFAULT nextval('ban_requests_id_seq'::regclass);
ALTER TABLE ONLY bazar_districts ALTER COLUMN id SET DEFAULT nextval('bazar_districts_id_seq'::regclass);
ALTER TABLE ONLY bets ALTER COLUMN id SET DEFAULT nextval('bets_id_seq'::regclass);
ALTER TABLE ONLY bets_categories ALTER COLUMN id SET DEFAULT nextval('bets_categories_id_seq'::regclass);
ALTER TABLE ONLY bets_options ALTER COLUMN id SET DEFAULT nextval('bets_options_id_seq'::regclass);
ALTER TABLE ONLY bets_tickets ALTER COLUMN id SET DEFAULT nextval('bets_tickets_id_seq'::regclass);
ALTER TABLE ONLY blogentries ALTER COLUMN id SET DEFAULT nextval('blogentries_id_seq'::regclass);
ALTER TABLE ONLY cash_movements ALTER COLUMN id SET DEFAULT nextval('cash_movements_id_seq'::regclass);
ALTER TABLE ONLY chatlines ALTER COLUMN id SET DEFAULT nextval('chatlines_id_seq'::regclass);
ALTER TABLE ONLY clans ALTER COLUMN id SET DEFAULT nextval('clans_id_seq'::regclass);
ALTER TABLE ONLY clans_friends ALTER COLUMN id SET DEFAULT nextval('clans_friends_id_seq'::regclass);
ALTER TABLE ONLY clans_groups ALTER COLUMN id SET DEFAULT nextval('clans_groups_id_seq'::regclass);
ALTER TABLE ONLY clans_groups_types ALTER COLUMN id SET DEFAULT nextval('clans_groups_types_id_seq'::regclass);
ALTER TABLE ONLY clans_logs_entries ALTER COLUMN id SET DEFAULT nextval('clans_logs_entries_id_seq'::regclass);
ALTER TABLE ONLY clans_movements ALTER COLUMN id SET DEFAULT nextval('clans_movements_id_seq'::regclass);
ALTER TABLE ONLY clans_sponsors ALTER COLUMN id SET DEFAULT nextval('clans_sponsors_id_seq'::regclass);
ALTER TABLE ONLY columns ALTER COLUMN id SET DEFAULT nextval('columns_id_seq'::regclass);
ALTER TABLE ONLY columns_categories ALTER COLUMN id SET DEFAULT nextval('columns_categories_id_seq'::regclass);
ALTER TABLE ONLY comment_violation_opinions ALTER COLUMN id SET DEFAULT nextval('comment_violation_opinions_id_seq'::regclass);
ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);
ALTER TABLE ONLY comments_valorations ALTER COLUMN id SET DEFAULT nextval('comments_valorations_id_seq'::regclass);
ALTER TABLE ONLY comments_valorations_types ALTER COLUMN id SET DEFAULT nextval('comments_valorations_types_id_seq'::regclass);
ALTER TABLE ONLY competitions ALTER COLUMN id SET DEFAULT nextval('competitions_id_seq'::regclass);
ALTER TABLE ONLY competitions_logs_entries ALTER COLUMN id SET DEFAULT nextval('competitions_logs_entries_id_seq'::regclass);
ALTER TABLE ONLY competitions_matches ALTER COLUMN id SET DEFAULT nextval('competitions_matches_id_seq'::regclass);
ALTER TABLE ONLY competitions_matches_clans_players ALTER COLUMN id SET DEFAULT nextval('competitions_matches_clans_players_id_seq'::regclass);
ALTER TABLE ONLY competitions_matches_games_maps ALTER COLUMN id SET DEFAULT nextval('competitions_matches_games_maps_id_seq'::regclass);
ALTER TABLE ONLY competitions_matches_reports ALTER COLUMN id SET DEFAULT nextval('competitions_matches_reports_id_seq'::regclass);
ALTER TABLE ONLY competitions_matches_uploads ALTER COLUMN id SET DEFAULT nextval('competitions_matches_uploads_id_seq'::regclass);
ALTER TABLE ONLY competitions_participants ALTER COLUMN id SET DEFAULT nextval('competitions_participants_id_seq'::regclass);
ALTER TABLE ONLY competitions_participants_types ALTER COLUMN id SET DEFAULT nextval('competitions_participants_types_id_seq'::regclass);
ALTER TABLE ONLY competitions_sponsors ALTER COLUMN id SET DEFAULT nextval('competitions_sponsors_id_seq'::regclass);
ALTER TABLE ONLY content_ratings ALTER COLUMN id SET DEFAULT nextval('content_ratings_id_seq'::regclass);
ALTER TABLE ONLY content_types ALTER COLUMN id SET DEFAULT nextval('content_types_id_seq'::regclass);
ALTER TABLE ONLY contents ALTER COLUMN id SET DEFAULT nextval('contents_id_seq'::regclass);
ALTER TABLE ONLY contents_locks ALTER COLUMN id SET DEFAULT nextval('contents_locks_id_seq'::regclass);
ALTER TABLE ONLY contents_recommendations ALTER COLUMN id SET DEFAULT nextval('contents_recommendations_id_seq'::regclass);
ALTER TABLE ONLY contents_terms ALTER COLUMN id SET DEFAULT nextval('contents_terms_id_seq'::regclass);
ALTER TABLE ONLY contents_versions ALTER COLUMN id SET DEFAULT nextval('contents_versions_id_seq'::regclass);
ALTER TABLE ONLY coverages ALTER COLUMN id SET DEFAULT nextval('events_news_id_seq'::regclass);
ALTER TABLE ONLY decision_choices ALTER COLUMN id SET DEFAULT nextval('decision_choices_id_seq'::regclass);
ALTER TABLE ONLY decision_comments ALTER COLUMN id SET DEFAULT nextval('decision_comments_id_seq'::regclass);
ALTER TABLE ONLY decision_user_choices ALTER COLUMN id SET DEFAULT nextval('decision_user_choices_id_seq'::regclass);
ALTER TABLE ONLY decision_user_reputations ALTER COLUMN id SET DEFAULT nextval('decision_user_reputations_id_seq'::regclass);
ALTER TABLE ONLY decisions ALTER COLUMN id SET DEFAULT nextval('decisions_id_seq'::regclass);
ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);
ALTER TABLE ONLY demo_mirrors ALTER COLUMN id SET DEFAULT nextval('demo_mirrors_id_seq'::regclass);
ALTER TABLE ONLY demos ALTER COLUMN id SET DEFAULT nextval('demos_id_seq'::regclass);
ALTER TABLE ONLY demos_categories ALTER COLUMN id SET DEFAULT nextval('demos_categories_id_seq'::regclass);
ALTER TABLE ONLY dictionary_words ALTER COLUMN id SET DEFAULT nextval('dictionary_words_id_seq'::regclass);
ALTER TABLE ONLY download_mirrors ALTER COLUMN id SET DEFAULT nextval('download_mirrors_id_seq'::regclass);
ALTER TABLE ONLY downloaded_downloads ALTER COLUMN id SET DEFAULT nextval('downloaded_downloads_id_seq'::regclass);
ALTER TABLE ONLY downloads ALTER COLUMN id SET DEFAULT nextval('downloads_id_seq'::regclass);
ALTER TABLE ONLY downloads_categories ALTER COLUMN id SET DEFAULT nextval('downloads_categories_id_seq'::regclass);
ALTER TABLE ONLY dudes ALTER COLUMN id SET DEFAULT nextval('dudes_id_seq'::regclass);
ALTER TABLE ONLY events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);
ALTER TABLE ONLY events_categories ALTER COLUMN id SET DEFAULT nextval('events_categories_id_seq'::regclass);
ALTER TABLE ONLY factions ALTER COLUMN id SET DEFAULT nextval('factions_id_seq'::regclass);
ALTER TABLE ONLY factions_banned_users ALTER COLUMN id SET DEFAULT nextval('factions_banned_users_id_seq'::regclass);
ALTER TABLE ONLY factions_capos ALTER COLUMN id SET DEFAULT nextval('factions_capos_id_seq'::regclass);
ALTER TABLE ONLY factions_editors ALTER COLUMN id SET DEFAULT nextval('factions_editors_id_seq'::regclass);
ALTER TABLE ONLY factions_headers ALTER COLUMN id SET DEFAULT nextval('factions_headers_id_seq'::regclass);
ALTER TABLE ONLY factions_links ALTER COLUMN id SET DEFAULT nextval('factions_links_id_seq'::regclass);
ALTER TABLE ONLY factions_portals ALTER COLUMN id SET DEFAULT nextval('factions_portals_id_seq'::regclass);
ALTER TABLE ONLY faq_categories ALTER COLUMN id SET DEFAULT nextval('faq_categories_id_seq'::regclass);
ALTER TABLE ONLY faq_entries ALTER COLUMN id SET DEFAULT nextval('faq_entries_id_seq'::regclass);
ALTER TABLE ONLY friends_recommendations ALTER COLUMN id SET DEFAULT nextval('friends_recommendations_id_seq'::regclass);
ALTER TABLE ONLY friendships ALTER COLUMN id SET DEFAULT nextval('friends_users_id_seq'::regclass);
ALTER TABLE ONLY funthings ALTER COLUMN id SET DEFAULT nextval('funthings_id_seq'::regclass);
ALTER TABLE ONLY gamersmafiageist_codes ALTER COLUMN id SET DEFAULT nextval('gamersmafiageist_codes_id_seq'::regclass);
ALTER TABLE ONLY games ALTER COLUMN id SET DEFAULT nextval('games_id_seq'::regclass);
ALTER TABLE ONLY games_maps ALTER COLUMN id SET DEFAULT nextval('games_maps_id_seq'::regclass);
ALTER TABLE ONLY games_modes ALTER COLUMN id SET DEFAULT nextval('games_modes_id_seq'::regclass);
ALTER TABLE ONLY games_versions ALTER COLUMN id SET DEFAULT nextval('games_versions_id_seq'::regclass);
ALTER TABLE ONLY gaming_platforms ALTER COLUMN id SET DEFAULT nextval('platforms_id_seq'::regclass);
ALTER TABLE ONLY global_vars ALTER COLUMN id SET DEFAULT nextval('global_vars_id_seq'::regclass);
ALTER TABLE ONLY gmtv_broadcast_messages ALTER COLUMN id SET DEFAULT nextval('gmtv_broadcast_messages_id_seq'::regclass);
ALTER TABLE ONLY gmtv_channels ALTER COLUMN id SET DEFAULT nextval('gmtv_channels_id_seq'::regclass);
ALTER TABLE ONLY groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);
ALTER TABLE ONLY groups_messages ALTER COLUMN id SET DEFAULT nextval('groups_messages_id_seq'::regclass);
ALTER TABLE ONLY images ALTER COLUMN id SET DEFAULT nextval('images_id_seq'::regclass);
ALTER TABLE ONLY images_categories ALTER COLUMN id SET DEFAULT nextval('images_categories_id_seq'::regclass);
ALTER TABLE ONLY interviews ALTER COLUMN id SET DEFAULT nextval('interviews_id_seq'::regclass);
ALTER TABLE ONLY interviews_categories ALTER COLUMN id SET DEFAULT nextval('interviews_categories_id_seq'::regclass);
ALTER TABLE ONLY ip_bans ALTER COLUMN id SET DEFAULT nextval('ip_bans_id_seq'::regclass);
ALTER TABLE ONLY ip_passwords_resets_requests ALTER COLUMN id SET DEFAULT nextval('ip_passwords_resets_requests_id_seq'::regclass);
ALTER TABLE ONLY macropolls ALTER COLUMN id SET DEFAULT nextval('macropolls_id_seq'::regclass);
ALTER TABLE ONLY macropolls_2007_1 ALTER COLUMN id SET DEFAULT nextval('macropolls_2007_1_id_seq'::regclass);
ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);
ALTER TABLE ONLY ne_references ALTER COLUMN id SET DEFAULT nextval('ne_references_id_seq'::regclass);
ALTER TABLE ONLY news ALTER COLUMN id SET DEFAULT nextval('news_id_seq'::regclass);
ALTER TABLE ONLY news_categories ALTER COLUMN id SET DEFAULT nextval('news_categories_id_seq'::regclass);
ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);
ALTER TABLE ONLY outstanding_entities ALTER COLUMN id SET DEFAULT nextval('outstanding_users_id_seq'::regclass);
ALTER TABLE ONLY polls ALTER COLUMN id SET DEFAULT nextval('polls_id_seq'::regclass);
ALTER TABLE ONLY polls_categories ALTER COLUMN id SET DEFAULT nextval('polls_categories_id_seq'::regclass);
ALTER TABLE ONLY polls_options ALTER COLUMN id SET DEFAULT nextval('polls_options_id_seq'::regclass);
ALTER TABLE ONLY polls_votes ALTER COLUMN id SET DEFAULT nextval('polls_votes_id_seq'::regclass);
ALTER TABLE ONLY portal_headers ALTER COLUMN id SET DEFAULT nextval('portal_headers_id_seq'::regclass);
ALTER TABLE ONLY portal_hits ALTER COLUMN id SET DEFAULT nextval('portal_hits_id_seq'::regclass);
ALTER TABLE ONLY portals ALTER COLUMN id SET DEFAULT nextval('portals_id_seq'::regclass);
ALTER TABLE ONLY potds ALTER COLUMN id SET DEFAULT nextval('potds_id_seq'::regclass);
ALTER TABLE ONLY products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);
ALTER TABLE ONLY profile_signatures ALTER COLUMN id SET DEFAULT nextval('profile_signatures_id_seq'::regclass);
ALTER TABLE ONLY questions ALTER COLUMN id SET DEFAULT nextval('questions_id_seq'::regclass);
ALTER TABLE ONLY questions_categories ALTER COLUMN id SET DEFAULT nextval('questions_categories_id_seq'::regclass);
ALTER TABLE ONLY recruitment_ads ALTER COLUMN id SET DEFAULT nextval('recruitment_ads_id_seq'::regclass);
ALTER TABLE ONLY refered_hits ALTER COLUMN id SET DEFAULT nextval('refered_hits_id_seq'::regclass);
ALTER TABLE ONLY reviews ALTER COLUMN id SET DEFAULT nextval('reviews_id_seq'::regclass);
ALTER TABLE ONLY reviews_categories ALTER COLUMN id SET DEFAULT nextval('reviews_categories_id_seq'::regclass);
ALTER TABLE ONLY sent_emails ALTER COLUMN id SET DEFAULT nextval('sent_emails_id_seq'::regclass);
ALTER TABLE ONLY silenced_emails ALTER COLUMN id SET DEFAULT nextval('silenced_emails_id_seq'::regclass);
ALTER TABLE ONLY skins ALTER COLUMN id SET DEFAULT nextval('skins_id_seq'::regclass);
ALTER TABLE ONLY skins_files ALTER COLUMN id SET DEFAULT nextval('skins_files_id_seq'::regclass);
ALTER TABLE ONLY sold_products ALTER COLUMN id SET DEFAULT nextval('sold_products_id_seq'::regclass);
ALTER TABLE ONLY staff_candidate_votes ALTER COLUMN id SET DEFAULT nextval('staff_candidate_votes_id_seq'::regclass);
ALTER TABLE ONLY staff_candidates ALTER COLUMN id SET DEFAULT nextval('staff_candidates_id_seq'::regclass);
ALTER TABLE ONLY staff_positions ALTER COLUMN id SET DEFAULT nextval('staff_positions_id_seq'::regclass);
ALTER TABLE ONLY staff_types ALTER COLUMN id SET DEFAULT nextval('staff_types_id_seq'::regclass);
ALTER TABLE ONLY terms ALTER COLUMN id SET DEFAULT nextval('terms_id_seq'::regclass);
ALTER TABLE ONLY topics ALTER COLUMN id SET DEFAULT nextval('forum_topics_id_seq'::regclass);
ALTER TABLE ONLY topics_categories ALTER COLUMN id SET DEFAULT nextval('forum_forums_id_seq'::regclass);
ALTER TABLE ONLY tracker_items ALTER COLUMN id SET DEFAULT nextval('tracker_items_id_seq'::regclass);
ALTER TABLE ONLY tutorials ALTER COLUMN id SET DEFAULT nextval('tutorials_id_seq'::regclass);
ALTER TABLE ONLY tutorials_categories ALTER COLUMN id SET DEFAULT nextval('tutorials_categories_id_seq'::regclass);
ALTER TABLE ONLY user_interests ALTER COLUMN id SET DEFAULT nextval('user_interests_id_seq'::regclass);
ALTER TABLE ONLY user_login_changes ALTER COLUMN id SET DEFAULT nextval('user_login_changes_id_seq'::regclass);
ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);
ALTER TABLE ONLY users_actions ALTER COLUMN id SET DEFAULT nextval('users_actions_id_seq'::regclass);
ALTER TABLE ONLY users_contents_tags ALTER COLUMN id SET DEFAULT nextval('users_contents_tags_id_seq'::regclass);
ALTER TABLE ONLY users_emblems ALTER COLUMN id SET DEFAULT nextval('users_emblems_id_seq'::regclass);
ALTER TABLE ONLY users_guids ALTER COLUMN id SET DEFAULT nextval('users_guids_id_seq'::regclass);
ALTER TABLE ONLY users_lastseen_ips ALTER COLUMN id SET DEFAULT nextval('users_lastseen_ips_id_seq'::regclass);
ALTER TABLE ONLY users_newsfeeds ALTER COLUMN id SET DEFAULT nextval('users_newsfeeds_id_seq'::regclass);
ALTER TABLE ONLY users_preferences ALTER COLUMN id SET DEFAULT nextval('users_preferences_id_seq'::regclass);
ALTER TABLE ONLY users_skills ALTER COLUMN id SET DEFAULT nextval('users_roles_id_seq'::regclass);
SET search_path = stats, pg_catalog;
ALTER TABLE ONLY ads ALTER COLUMN id SET DEFAULT nextval('ads_id_seq'::regclass);
ALTER TABLE ONLY ads_daily ALTER COLUMN id SET DEFAULT nextval('ads_daily_id_seq'::regclass);
ALTER TABLE ONLY bandit_treatments ALTER COLUMN id SET DEFAULT nextval('bandit_treatments_id_seq'::regclass);
ALTER TABLE ONLY bets_results ALTER COLUMN id SET DEFAULT nextval('bets_results_id_seq'::regclass);
ALTER TABLE ONLY clans_daily_stats ALTER COLUMN id SET DEFAULT nextval('clans_daily_stats_id_seq'::regclass);
ALTER TABLE ONLY pageloadtime ALTER COLUMN id SET DEFAULT nextval('pageloadtime_id_seq'::regclass);
ALTER TABLE ONLY pageviews ALTER COLUMN id SET DEFAULT nextval('pageviews_id_seq'::regclass);
ALTER TABLE ONLY portals ALTER COLUMN id SET DEFAULT nextval('portals_stats_id_seq'::regclass);
ALTER TABLE ONLY users_daily_stats ALTER COLUMN id SET DEFAULT nextval('users_daily_stats_id_seq'::regclass);
ALTER TABLE ONLY users_karma_daily_by_portal ALTER COLUMN id SET DEFAULT nextval('users_karma_daily_by_portal_id_seq'::regclass);
SET search_path = archive, pg_catalog;
ALTER TABLE ONLY pageviews
    ADD CONSTRAINT pageviews_pkey PRIMARY KEY (id);
ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_pkey PRIMARY KEY (id);
SET search_path = public, pg_catalog;
ALTER TABLE ONLY ab_tests
    ADD CONSTRAINT ab_tests_name_key UNIQUE (name);
ALTER TABLE ONLY ab_tests
    ADD CONSTRAINT ab_tests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_name_key UNIQUE (name);
ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ads_slots_instances
    ADD CONSTRAINT ads_slots_instances_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_name_key UNIQUE (name);
ALTER TABLE ONLY ads_slots
    ADD CONSTRAINT ads_slots_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ads_slots_portals
    ADD CONSTRAINT ads_slots_portals_pkey PRIMARY KEY (id);
ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_email_key UNIQUE (email);
ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_name_key UNIQUE (name);
ALTER TABLE ONLY advertisers
    ADD CONSTRAINT advertisers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY allowed_competitions_participants
    ADD CONSTRAINT allowed_competitions_participants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY autologin_keys
    ADD CONSTRAINT autologin_keys_pkey PRIMARY KEY (id);
ALTER TABLE ONLY avatars
    ADD CONSTRAINT avatars_pkey PRIMARY KEY (id);
ALTER TABLE ONLY babes
    ADD CONSTRAINT babes_date_key UNIQUE (date);
ALTER TABLE ONLY babes
    ADD CONSTRAINT babes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ban_requests
    ADD CONSTRAINT ban_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_code_key UNIQUE (slug);
ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_name_key UNIQUE (name);
ALTER TABLE ONLY bazar_districts
    ADD CONSTRAINT bazar_districts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bets_categories
    ADD CONSTRAINT bets_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bets_options
    ADD CONSTRAINT bets_options_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bets_tickets
    ADD CONSTRAINT bets_tickets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY cash_movements
    ADD CONSTRAINT cash_movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY chatlines
    ADD CONSTRAINT chatlines_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_friends
    ADD CONSTRAINT clans_friends_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_games
    ADD CONSTRAINT clans_games_pkey PRIMARY KEY (clan_id, game_id);
ALTER TABLE ONLY clans_groups
    ADD CONSTRAINT clans_groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_name_key UNIQUE (name);
ALTER TABLE ONLY clans_groups_types
    ADD CONSTRAINT clans_groups_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_logs_entries
    ADD CONSTRAINT clans_logs_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_movements
    ADD CONSTRAINT clans_movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_name_key UNIQUE (name);
ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_sponsors
    ADD CONSTRAINT clans_sponsors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_tag_key UNIQUE (tag);
ALTER TABLE ONLY columns_categories
    ADD CONSTRAINT columns_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY comment_violation_opinions
    ADD CONSTRAINT comment_violation_opinions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY comments_valorations_types
    ADD CONSTRAINT comments_valorations_types_name_key UNIQUE (name);
ALTER TABLE ONLY comments_valorations_types
    ADD CONSTRAINT comments_valorations_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_admins
    ADD CONSTRAINT competitions_admins_pkey PRIMARY KEY (competition_id, user_id);
ALTER TABLE ONLY competitions_games_maps
    ADD CONSTRAINT competitions_games_maps_pkey PRIMARY KEY (competition_id, games_map_id);
ALTER TABLE ONLY competitions_logs_entries
    ADD CONSTRAINT competitions_logs_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_matches_clans_players
    ADD CONSTRAINT competitions_matches_clans_players_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_matches_games_maps
    ADD CONSTRAINT competitions_matches_games_maps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_matches_reports
    ADD CONSTRAINT competitions_matches_reports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_matches_uploads
    ADD CONSTRAINT competitions_matches_uploads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_name_key UNIQUE (name);
ALTER TABLE ONLY competitions_participants
    ADD CONSTRAINT competitions_participants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_participants_types
    ADD CONSTRAINT competitions_participants_types_name_key UNIQUE (name);
ALTER TABLE ONLY competitions_participants_types
    ADD CONSTRAINT competitions_participants_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions
    ADD CONSTRAINT competitions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_sponsors
    ADD CONSTRAINT competitions_sponsors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY competitions_supervisors
    ADD CONSTRAINT competitions_supervisors_pkey PRIMARY KEY (competition_id, user_id);
ALTER TABLE ONLY content_ratings
    ADD CONSTRAINT content_ratings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_name_key UNIQUE (name);
ALTER TABLE ONLY content_types
    ADD CONSTRAINT content_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_content_type_id_key UNIQUE (content_type_id, external_id);
ALTER TABLE ONLY contents_locks
    ADD CONSTRAINT contents_locks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contents_recommendations
    ADD CONSTRAINT contents_recommendations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_pkey PRIMARY KEY (id);
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_url_key UNIQUE (url);
ALTER TABLE ONLY contents_versions
    ADD CONSTRAINT contents_versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY decision_choices
    ADD CONSTRAINT decision_choices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY decision_comments
    ADD CONSTRAINT decision_comments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY decision_user_choices
    ADD CONSTRAINT decision_user_choices_pkey PRIMARY KEY (id);
ALTER TABLE ONLY decision_user_reputations
    ADD CONSTRAINT decision_user_reputations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY decisions
    ADD CONSTRAINT decisions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY demo_mirrors
    ADD CONSTRAINT demo_mirrors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY demos_categories
    ADD CONSTRAINT demos_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY dictionary_words
    ADD CONSTRAINT dictionary_words_name_key UNIQUE (name);
ALTER TABLE ONLY dictionary_words
    ADD CONSTRAINT dictionary_words_pkey PRIMARY KEY (id);
ALTER TABLE ONLY downloaded_downloads
    ADD CONSTRAINT downloaded_downloads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY download_mirrors
    ADD CONSTRAINT downloadmirrors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY downloads_categories
    ADD CONSTRAINT downloads_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_path_key UNIQUE (file);
ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY dudes
    ADD CONSTRAINT dudes_date_key UNIQUE (date);
ALTER TABLE ONLY dudes
    ADD CONSTRAINT dudes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY events_categories
    ADD CONSTRAINT events_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_pkey PRIMARY KEY (id);
ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions_banned_users
    ADD CONSTRAINT factions_banned_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_bottom_key UNIQUE (building_bottom);
ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_middle_key UNIQUE (building_middle);
ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_building_top_key UNIQUE (building_top);
ALTER TABLE ONLY factions_capos
    ADD CONSTRAINT factions_capos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_code_key UNIQUE (code);
ALTER TABLE ONLY factions_editors
    ADD CONSTRAINT factions_editors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions_headers
    ADD CONSTRAINT factions_headers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions_links
    ADD CONSTRAINT factions_links_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_name_key UNIQUE (name);
ALTER TABLE ONLY factions
    ADD CONSTRAINT factions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY factions_portals
    ADD CONSTRAINT factions_portals_pkey PRIMARY KEY (faction_id, portal_id);
ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_name_key UNIQUE (name);
ALTER TABLE ONLY faq_categories
    ADD CONSTRAINT faq_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY faq_entries
    ADD CONSTRAINT faq_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY topics_categories
    ADD CONSTRAINT forum_forums_pkey PRIMARY KEY (id);
ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_pkey PRIMARY KEY (id);
ALTER TABLE ONLY friends_recommendations
    ADD CONSTRAINT friends_recommendations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_external_invitation_key_key UNIQUE (external_invitation_key);
ALTER TABLE ONLY friendships
    ADD CONSTRAINT friends_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_url_key UNIQUE (main);
ALTER TABLE ONLY gamersmafiageist_codes
    ADD CONSTRAINT gamersmafiageist_codes_code_key UNIQUE (code);
ALTER TABLE ONLY gamersmafiageist_codes
    ADD CONSTRAINT gamersmafiageist_codes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY games_maps
    ADD CONSTRAINT games_maps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY games_modes
    ADD CONSTRAINT games_modes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);
ALTER TABLE ONLY games_gaming_platforms
    ADD CONSTRAINT games_platforms_pkey PRIMARY KEY (game_id, gaming_platform_id);
ALTER TABLE ONLY games_versions
    ADD CONSTRAINT games_versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY global_vars
    ADD CONSTRAINT global_vars_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gmtv_broadcast_messages
    ADD CONSTRAINT gmtv_broadcast_messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gmtv_channels
    ADD CONSTRAINT gmtv_channels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);
ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY images_categories
    ADD CONSTRAINT images_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY images
    ADD CONSTRAINT images_path_key UNIQUE (file);
ALTER TABLE ONLY images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);
ALTER TABLE ONLY interviews_categories
    ADD CONSTRAINT interviews_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ip_bans
    ADD CONSTRAINT ip_bans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ip_passwords_resets_requests
    ADD CONSTRAINT ip_passwords_resets_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY macropolls_2007_1
    ADD CONSTRAINT macropolls_2007_1_pkey PRIMARY KEY (id);
ALTER TABLE ONLY macropolls
    ADD CONSTRAINT macropolls_pkey PRIMARY KEY (id);
ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ne_references
    ADD CONSTRAINT ne_references_pkey PRIMARY KEY (id);
ALTER TABLE ONLY news_categories
    ADD CONSTRAINT news_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);
ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
ALTER TABLE ONLY outstanding_entities
    ADD CONSTRAINT outstanding_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gaming_platforms
    ADD CONSTRAINT platforms_code_key UNIQUE (slug);
ALTER TABLE ONLY gaming_platforms
    ADD CONSTRAINT platforms_name_key UNIQUE (name);
ALTER TABLE ONLY gaming_platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (id);
ALTER TABLE ONLY polls_categories
    ADD CONSTRAINT polls_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_pkey PRIMARY KEY (id);
ALTER TABLE ONLY polls_options
    ADD CONSTRAINT polls_options_poll_id_key UNIQUE (poll_id, name);
ALTER TABLE ONLY polls_votes
    ADD CONSTRAINT polls_options_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);
ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_title_key UNIQUE (title);
ALTER TABLE ONLY portal_headers
    ADD CONSTRAINT portal_headers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY portal_hits
    ADD CONSTRAINT portal_hits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_code_key UNIQUE (code);
ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_pkey PRIMARY KEY (id);
ALTER TABLE ONLY portals_skins
    ADD CONSTRAINT portals_skins_pkey PRIMARY KEY (portal_id, skin_id);
ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_pkey PRIMARY KEY (id);
ALTER TABLE ONLY products
    ADD CONSTRAINT products_cls_key UNIQUE (cls);
ALTER TABLE ONLY products
    ADD CONSTRAINT products_name_key UNIQUE (name);
ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY profile_signatures
    ADD CONSTRAINT profile_signatures_pkey PRIMARY KEY (id);
ALTER TABLE ONLY questions_categories
    ADD CONSTRAINT questions_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY refered_hits
    ADD CONSTRAINT refered_hits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY reviews_categories
    ADD CONSTRAINT reviews_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);
ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_version_key UNIQUE (version);
ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_message_key_key UNIQUE (message_key);
ALTER TABLE ONLY sent_emails
    ADD CONSTRAINT sent_emails_pkey PRIMARY KEY (id);
ALTER TABLE ONLY silenced_emails
    ADD CONSTRAINT silenced_emails_email_key UNIQUE (email);
ALTER TABLE ONLY silenced_emails
    ADD CONSTRAINT silenced_emails_pkey PRIMARY KEY (id);
ALTER TABLE ONLY skins_files
    ADD CONSTRAINT skins_files_pkey PRIMARY KEY (id);
ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_hid_key UNIQUE (hid);
ALTER TABLE ONLY skins
    ADD CONSTRAINT skins_pkey PRIMARY KEY (id);
ALTER TABLE ONLY alerts
    ADD CONSTRAINT slog_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY sold_products
    ADD CONSTRAINT sold_products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY staff_candidate_votes
    ADD CONSTRAINT staff_candidate_votes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY staff_candidates
    ADD CONSTRAINT staff_candidates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY staff_positions
    ADD CONSTRAINT staff_positions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY staff_types
    ADD CONSTRAINT staff_types_name_key UNIQUE (name);
ALTER TABLE ONLY staff_types
    ADD CONSTRAINT staff_types_pkey PRIMARY KEY (id);
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tracker_items
    ADD CONSTRAINT tracker_items_pkey1 PRIMARY KEY (id);
ALTER TABLE ONLY treated_visitors
    ADD CONSTRAINT treated_visitors_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tutorials_categories
    ADD CONSTRAINT tutorials_categories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_pkey PRIMARY KEY (id);
ALTER TABLE ONLY user_interests
    ADD CONSTRAINT user_interests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY user_login_changes
    ADD CONSTRAINT user_login_changes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_actions
    ADD CONSTRAINT users_actions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_emblems
    ADD CONSTRAINT users_emblems_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_guids
    ADD CONSTRAINT users_guids_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_lastseen_ips
    ADD CONSTRAINT users_lastseen_ips_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_newsfeeds
    ADD CONSTRAINT users_newsfeeds_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_preferences
    ADD CONSTRAINT users_preferences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_skills
    ADD CONSTRAINT users_roles_pkey PRIMARY KEY (id);
SET search_path = stats, pg_catalog;
ALTER TABLE ONLY ads_daily
    ADD CONSTRAINT ads_daily_pkey PRIMARY KEY (id);
ALTER TABLE ONLY ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bandit_treatments
    ADD CONSTRAINT bandit_treatments_abtest_treatment_key UNIQUE (abtest_treatment);
ALTER TABLE ONLY bandit_treatments
    ADD CONSTRAINT bandit_treatments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY bets_results
    ADD CONSTRAINT bets_results_pkey PRIMARY KEY (id);
ALTER TABLE ONLY clans_daily_stats
    ADD CONSTRAINT clans_daily_stats_pkey PRIMARY KEY (id);
ALTER TABLE ONLY general
    ADD CONSTRAINT general_pkey PRIMARY KEY (created_on);
ALTER TABLE ONLY pageloadtime
    ADD CONSTRAINT pageloadtime_pkey PRIMARY KEY (id);
ALTER TABLE ONLY pageviews
    ADD CONSTRAINT pageviews_pkey PRIMARY KEY (id);
ALTER TABLE ONLY portals
    ADD CONSTRAINT portals_stats_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_daily_stats
    ADD CONSTRAINT users_daily_stats_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users_karma_daily_by_portal
    ADD CONSTRAINT users_karma_daily_by_portal_pkey PRIMARY KEY (id);
SET search_path = archive, pg_catalog;
CREATE UNIQUE INDEX tracker_items_pkey ON tracker_items USING btree (id);
SET search_path = public, pg_catalog;
CREATE UNIQUE INDEX autologin_keys_key ON autologin_keys USING btree (key);
CREATE INDEX autologin_keys_lastused_on ON autologin_keys USING btree (lastused_on);
CREATE INDEX avatars_clan_id ON avatars USING btree (clan_id);
CREATE INDEX avatars_faction_id ON avatars USING btree (faction_id);
CREATE UNIQUE INDEX avatars_name_faction_id ON avatars USING btree (name, faction_id);
CREATE INDEX avatars_user_id ON avatars USING btree (user_id);
CREATE INDEX bets_approved_by_user_id ON bets USING btree (approved_by_user_id);
CREATE UNIQUE INDEX bets_categories_unique ON bets_categories USING btree (name, parent_id);
CREATE INDEX bets_state ON bets USING btree (state);
CREATE INDEX bets_tickets_user_id ON bets_tickets USING btree (user_id);
CREATE INDEX bets_user_id ON bets USING btree (user_id);
CREATE INDEX blogentries_published ON blogentries USING btree (user_id, deleted);
CREATE INDEX blogentries_state ON blogentries USING btree (state);
CREATE INDEX cash_movements_from ON cash_movements USING btree (object_id_from, object_id_from_class);
CREATE INDEX cash_movements_to ON cash_movements USING btree (object_id_to, object_id_to_class);
CREATE INDEX chatlines_created_on ON chatlines USING btree (created_on);
CREATE UNIQUE INDEX clans_groups_r_users_group_user ON clans_groups_users USING btree (clans_group_id, user_id);
CREATE INDEX clans_groups_types_name ON clans_groups_types USING btree (name);
CREATE UNIQUE INDEX clans_r_games_clan_game ON clans_games USING btree (clan_id, game_id);
CREATE INDEX clans_r_games_clan_id ON clans_games USING btree (clan_id);
CREATE INDEX clans_r_games_game_id ON clans_games USING btree (game_id);
CREATE UNIQUE INDEX clans_sponsors_clan_id_name ON clans_sponsors USING btree (clan_id, name);
CREATE INDEX clans_tag ON clans USING btree (tag);
CREATE INDEX columns_appr_and_not_deleted ON columns USING btree (approved_by_user_id, deleted);
CREATE INDEX columns_approved_by_user_id ON columns USING btree (approved_by_user_id);
CREATE UNIQUE INDEX columns_categories_unique ON columns_categories USING btree (name, parent_id);
CREATE INDEX columns_state ON columns USING btree (state);
CREATE INDEX columns_user_id ON columns USING btree (user_id);
CREATE UNIQUE INDEX comment_violation_opinion ON comment_violation_opinions USING btree (user_id, comment_id);
CREATE INDEX comment_violation_opinions_user_id ON comment_violation_opinions USING btree (user_id);
CREATE INDEX comments_content_id ON comments USING btree (content_id);
CREATE INDEX comments_created_on ON comments USING btree (created_on);
CREATE INDEX comments_created_on_content_id ON comments USING btree (created_on, content_id);
CREATE INDEX comments_created_on_date_trunc ON comments USING btree (date_trunc('day'::text, created_on));
CREATE INDEX comments_has_comments_valorations_user_id ON comments USING btree (has_comments_valorations, user_id);
CREATE INDEX comments_netiquette_violations ON comments USING btree (netiquette_violation);
CREATE INDEX comments_random_v ON comments USING btree (random_v);
CREATE INDEX comments_user_id_created_on ON comments USING btree (user_id, created_on);
CREATE UNIQUE INDEX comments_valorations_comment_id_user_id ON comments_valorations USING btree (comment_id, user_id);
CREATE UNIQUE INDEX competitions_games_maps_uniq ON competitions_games_maps USING btree (competition_id, games_map_id);
CREATE INDEX competitions_matches_competition_id ON competitions_matches USING btree (competition_id);
CREATE INDEX competitions_matches_event_id ON competitions_matches USING btree (event_id);
CREATE INDEX competitions_matches_participant1_id ON competitions_matches USING btree (participant1_id);
CREATE INDEX competitions_matches_participant2_id ON competitions_matches USING btree (participant2_id);
CREATE INDEX competitions_participants_competition_id ON competitions_participants USING btree (competition_id);
CREATE UNIQUE INDEX competitions_participants_uniq ON competitions_participants USING btree (competition_id, participant_id, competitions_participants_type_id);
CREATE UNIQUE INDEX competitions_supervisors_uniq ON competitions_supervisors USING btree (competition_id, user_id);
CREATE INDEX content_ratings_comb ON content_ratings USING btree (ip, user_id, created_on);
CREATE UNIQUE INDEX content_ratings_user_id_content_id ON content_ratings USING btree (user_id, content_id);
CREATE INDEX contents_created_on ON contents USING btree (created_on);
CREATE INDEX contents_id_state_content_type_id ON contents USING btree (id, state, content_type_id);
CREATE INDEX contents_is_public ON contents USING btree (is_public);
CREATE INDEX contents_is_public_and_game_id ON contents USING btree (is_public, game_id);
CREATE UNIQUE INDEX contents_locks_uniq ON contents_locks USING btree (content_id);
CREATE UNIQUE INDEX contents_recommendations_content_id_sender_user_id_receiver_use ON contents_recommendations USING btree (content_id, sender_user_id, receiver_user_id);
CREATE INDEX contents_recommendations_receiver_user_id_marked_as_bad ON contents_recommendations USING btree (receiver_user_id, marked_as_bad);
CREATE INDEX contents_recommendations_seen_on_content_id_receiver_user_id ON contents_recommendations USING btree (content_id, receiver_user_id);
CREATE INDEX contents_recommendations_sender_user_id ON contents_recommendations USING btree (sender_user_id);
CREATE INDEX contents_state ON contents USING btree (state);
CREATE INDEX contents_state_clan_id ON contents USING btree (state, clan_id);
CREATE INDEX contents_terms_content_id ON contents_terms USING btree (content_id);
CREATE INDEX contents_terms_term_id ON contents_terms USING btree (term_id);
CREATE UNIQUE INDEX contents_terms_uniq ON contents_terms USING btree (content_id, term_id);
CREATE INDEX contents_user_id_state ON contents USING btree (user_id, state);
CREATE INDEX decision_choices_common ON decision_choices USING btree (decision_id);
CREATE INDEX decision_comments_decision_idx ON decision_comments USING btree (decision_id);
CREATE INDEX decision_comments_user_idx ON decision_comments USING btree (user_id);
CREATE INDEX decision_final_decision_choice_id ON decisions USING btree (final_decision_choice_id);
CREATE INDEX decision_user_choices_uniq ON decision_user_choices USING btree (decision_id, user_id);
CREATE INDEX decisions_type_class_state ON decisions USING btree (decision_type_class, state);
CREATE UNIQUE INDEX decisions_user_reputation_uniq ON decision_user_reputations USING btree (user_id, decision_type_class);
CREATE INDEX demos_approved_by_user_id ON demos USING btree (approved_by_user_id);
CREATE INDEX demos_approved_by_user_id_deleted ON demos USING btree (approved_by_user_id, deleted);
CREATE UNIQUE INDEX demos_categories_unique ON demos_categories USING btree (name, parent_id);
CREATE UNIQUE INDEX demos_file ON demos USING btree (file);
CREATE UNIQUE INDEX demos_hash_md5 ON demos USING btree (file_hash_md5);
CREATE INDEX demos_state ON demos USING btree (state);
CREATE INDEX demos_user_id ON demos USING btree (user_id);
CREATE INDEX downloads_approved_by_user_id ON downloads USING btree (approved_by_user_id);
CREATE UNIQUE INDEX downloads_categories_unique ON downloads_categories USING btree (name, parent_id);
CREATE INDEX downloads_hash_md5 ON downloads USING btree (file_hash_md5);
CREATE INDEX downloads_state ON downloads USING btree (state);
CREATE INDEX downloads_user_id ON downloads USING btree (user_id);
CREATE INDEX events_appr_and_not_deleted ON events USING btree (approved_by_user_id, deleted);
CREATE INDEX events_approved_by_user_id ON events USING btree (approved_by_user_id);
CREATE INDEX events_news_approved_by_user_id ON coverages USING btree (approved_by_user_id);
CREATE INDEX events_news_state ON coverages USING btree (state);
CREATE INDEX events_news_user_id ON coverages USING btree (user_id);
CREATE INDEX events_state ON events USING btree (state);
CREATE INDEX events_user_id ON events USING btree (user_id);
CREATE UNIQUE INDEX factions_banned_users_fu ON factions_banned_users USING btree (faction_id, user_id);
CREATE UNIQUE INDEX factions_capos_uniq ON factions_capos USING btree (faction_id, user_id);
CREATE UNIQUE INDEX factions_editors_uniq ON factions_editors USING btree (faction_id, user_id, content_type_id);
CREATE INDEX factions_headers_lasttime_used_on ON factions_headers USING btree (lasttime_used_on);
CREATE UNIQUE INDEX factions_headers_names_faction_id ON factions_headers USING btree (faction_id, name);
CREATE UNIQUE INDEX factions_links_names_faction_id ON factions_links USING btree (faction_id, name);
CREATE UNIQUE INDEX forum_forums_code_name_parent_id ON topics_categories USING btree (code, name, parent_id);
CREATE INDEX forum_topics_state ON topics USING btree (state);
CREATE INDEX forum_topics_user_id ON topics USING btree (user_id);
CREATE UNIQUE INDEX friends_recommendations_uniq ON friends_recommendations USING btree (user_id, recommended_user_id);
CREATE INDEX friends_recommendations_user_id_undecided ON friends_recommendations USING btree (user_id, added_as_friend);
CREATE UNIQUE INDEX friends_users_uniq ON friendships USING btree (sender_user_id, receiver_user_id);
CREATE INDEX funthings_state ON funthings USING btree (state);
CREATE UNIQUE INDEX funthings_title_uniq ON funthings USING btree (title);
CREATE INDEX games_gaming_platform ON games USING btree (gaming_platform_id);
CREATE INDEX games_has_competitions ON games USING btree (has_competitions);
CREATE INDEX games_has_demos ON games USING btree (has_demos);
CREATE INDEX games_has_game_maps ON games USING btree (has_game_maps);
CREATE UNIQUE INDEX games_maps_name_game_id ON games_maps USING btree (name, game_id);
CREATE UNIQUE INDEX games_modes_uniq ON games_modes USING btree (name, game_id);
CREATE UNIQUE INDEX games_name_platform ON games USING btree (name, gaming_platform_id);
CREATE INDEX games_users_game_id ON games_users USING btree (game_id);
CREATE UNIQUE INDEX games_users_uniq ON games_users USING btree (user_id, game_id);
CREATE INDEX games_users_user_id ON games_users USING btree (user_id);
CREATE UNIQUE INDEX games_versions_uniq ON games_versions USING btree (version, game_id);
CREATE INDEX images_approved_by_user_id ON images USING btree (approved_by_user_id);
CREATE UNIQUE INDEX images_categories_unique ON images_categories USING btree (name, parent_id);
CREATE INDEX images_hash_md5 ON images USING btree (file_hash_md5);
CREATE INDEX images_state ON images USING btree (state);
CREATE INDEX images_user_id ON images USING btree (user_id);
CREATE INDEX interviews_approved_by_user_id ON interviews USING btree (approved_by_user_id);
CREATE UNIQUE INDEX interviews_categories_unique ON interviews_categories USING btree (name, parent_id);
CREATE INDEX interviews_state ON interviews USING btree (state);
CREATE INDEX interviews_user_id ON interviews USING btree (user_id);
CREATE INDEX ip_passwords_resets_requests_ip_created_on ON ip_passwords_resets_requests USING btree (ip, created_on);
CREATE INDEX messages_user_id_is_read ON messages USING btree (user_id_to) WHERE (is_read IS FALSE);
CREATE INDEX ne_references_entity ON ne_references USING btree (entity_class, entity_id);
CREATE INDEX ne_references_referencer ON ne_references USING btree (referencer_class, referencer_id);
CREATE UNIQUE INDEX ne_references_uniq ON ne_references USING btree (entity_class, entity_id, referencer_class, referencer_id);
CREATE INDEX news_approved_by_user_id ON news USING btree (approved_by_user_id);
CREATE UNIQUE INDEX news_categories_unique ON news_categories USING btree (name, parent_id);
CREATE INDEX news_state ON news USING btree (state);
CREATE INDEX news_user_id ON news USING btree (user_id);
CREATE INDEX notifications_common ON notifications USING btree (user_id, read_on);
CREATE INDEX notifications_type_id ON notifications USING btree (user_id, type_id);
CREATE UNIQUE INDEX outstanding_entities_uniq ON outstanding_entities USING btree (type, portal_id, active_on);
CREATE INDEX platforms_users_platform_id ON gaming_platforms_users USING btree (gaming_platform_id);
CREATE UNIQUE INDEX platforms_users_platform_id_user_id ON gaming_platforms_users USING btree (user_id, gaming_platform_id);
CREATE INDEX platforms_users_user_id ON gaming_platforms_users USING btree (user_id);
CREATE INDEX polls_approved_by_user_id ON polls USING btree (approved_by_user_id);
CREATE UNIQUE INDEX polls_categories_code_parent_id ON polls_categories USING btree (code, parent_id);
CREATE UNIQUE INDEX polls_categories_name_parent_id ON polls_categories USING btree (name, parent_id);
CREATE INDEX polls_state ON polls USING btree (state);
CREATE INDEX polls_user_id ON polls USING btree (user_id);
CREATE UNIQUE INDEX portal_hits_uniq ON portal_hits USING btree (portal_id, date);
CREATE UNIQUE INDEX portals_name_code_type ON portals USING btree (name, code, type);
CREATE UNIQUE INDEX potds_uniq ON potds USING btree (date, portal_id, images_category_id);
CREATE INDEX profile_signatures_user_id ON profile_signatures USING btree (user_id);
CREATE UNIQUE INDEX profile_signatures_user_id_signer_user_id ON profile_signatures USING btree (user_id, signer_user_id);
CREATE UNIQUE INDEX questions_categories_code_name_parent_id ON questions_categories USING btree (code, name, parent_id);
CREATE INDEX questions_state ON questions USING btree (state);
CREATE INDEX questions_user_id ON questions USING btree (user_id);
CREATE INDEX refered_hits_user_id ON refered_hits USING btree (user_id);
CREATE INDEX reviews_approved_by_user_id ON reviews USING btree (approved_by_user_id);
CREATE UNIQUE INDEX reviews_categories_unique ON reviews_categories USING btree (name, parent_id);
CREATE INDEX reviews_state ON reviews USING btree (state);
CREATE INDEX reviews_user_id ON reviews USING btree (user_id);
CREATE INDEX sent_emails_created_on ON sent_emails USING btree (created_on);
CREATE INDEX silenced_emails_lower ON silenced_emails USING btree (lower((email)::text));
CREATE INDEX slog_entries_completed_on ON alerts USING btree (completed_on);
CREATE INDEX slog_entries_headline ON alerts USING btree (headline);
CREATE INDEX slog_entries_scope ON alerts USING btree (scope);
CREATE INDEX slog_type_id ON alerts USING btree (type_id);
CREATE UNIQUE INDEX staff_candidates_uniq ON staff_candidates USING btree (staff_position_id, user_id, term_starts_on);
CREATE INDEX terms_lower_name ON terms USING btree (lower((name)::text));
CREATE INDEX terms_name_uniq ON terms USING btree (game_id, bazar_district_id, gaming_platform_id, clan_id, taxonomy, parent_id, name);
CREATE INDEX terms_parent_id ON terms USING btree (parent_id);
CREATE INDEX terms_root_id ON terms USING btree (root_id);
CREATE INDEX terms_root_id_parent_id_taxonomy ON terms USING btree (root_id, parent_id, taxonomy);
CREATE INDEX terms_slug_toplevel ON terms USING btree (slug) WHERE (parent_id IS NULL);
CREATE INDEX terms_slug_uniq ON terms USING btree (game_id, bazar_district_id, gaming_platform_id, clan_id, taxonomy, parent_id, slug);
CREATE UNIQUE INDEX tracker_items_content_id_user_id ON tracker_items USING btree (content_id, user_id);
CREATE INDEX tracker_items_full ON tracker_items USING btree (content_id, user_id, lastseen_on, is_tracked);
CREATE INDEX tracker_items_user_id_is_tracked ON tracker_items USING btree (user_id, is_tracked) WHERE (is_tracked = true);
CREATE INDEX treated_visitors_multi ON treated_visitors USING btree (ab_test_id, visitor_id, treatment);
CREATE UNIQUE INDEX treated_visitors_per_test ON treated_visitors USING btree (ab_test_id, visitor_id);
CREATE INDEX tutorials_approved_by_user_id ON tutorials USING btree (approved_by_user_id);
CREATE UNIQUE INDEX tutorials_categories_unique ON tutorials_categories USING btree (name, parent_id);
CREATE INDEX tutorials_state ON tutorials USING btree (state);
CREATE INDEX tutorials_user_id ON tutorials USING btree (user_id);
CREATE INDEX user_interests_entity_class_entity_id ON user_interests USING btree (entity_type_class, entity_id);
CREATE INDEX user_interests_show_in_menu ON user_interests USING btree (user_id, show_in_menu);
CREATE UNIQUE INDEX user_interests_uniq ON user_interests USING btree (user_id, entity_type_class, entity_id);
CREATE INDEX user_interests_user_id ON user_interests USING btree (user_id);
CREATE INDEX users_actions_created_on ON users_actions USING btree (created_on);
CREATE INDEX users_cache_remaning ON users USING btree (cache_remaining_rating_slots) WHERE (cache_remaining_rating_slots IS NOT NULL);
CREATE UNIQUE INDEX users_comments_sig ON users USING btree (comments_sig);
CREATE INDEX users_contents_tags_content_id ON users_contents_tags USING btree (content_id);
CREATE INDEX users_contents_tags_term_id ON users_contents_tags USING btree (term_id);
CREATE INDEX users_contents_tags_user_id ON users_contents_tags USING btree (user_id);
CREATE INDEX users_email_id ON users USING btree (email, id);
CREATE INDEX users_emblems_created_on ON users_emblems USING btree (created_on);
CREATE INDEX users_emblems_user_id ON users_emblems USING btree (user_id);
CREATE INDEX users_faction_id ON users USING btree (faction_id);
CREATE UNIQUE INDEX users_guids_uniq ON users_guids USING btree (guid, game_id);
CREATE INDEX users_lastseen ON users USING btree (lastseen_on);
CREATE INDEX users_login_ne_unfriendly ON users USING btree (login_is_ne_unfriendly);
CREATE INDEX users_lower_all ON users USING btree (lower((login)::text), lower((email)::text), lower((firstname)::text), lower((lastname)::text), ipaddr);
CREATE INDEX users_lower_login ON users USING btree (lower((login)::text));
CREATE INDEX users_newsfeeds_created_on ON users_newsfeeds USING btree (created_on);
CREATE INDEX users_newsfeeds_created_on_user_id ON users_newsfeeds USING btree (created_on, user_id);
CREATE UNIQUE INDEX users_preferences_user_id_name ON users_preferences USING btree (user_id, name);
CREATE INDEX users_random_id ON users USING btree (random_id);
CREATE INDEX users_referer_user_id ON users USING btree (referer_user_id);
CREATE INDEX users_roles_role ON users_skills USING btree (role);
CREATE INDEX users_roles_role_role_data ON users_skills USING btree (role, role_data);
CREATE UNIQUE INDEX users_roles_uniq ON users_skills USING btree (user_id, role, role_data);
CREATE INDEX users_roles_user_id ON users_skills USING btree (user_id);
CREATE UNIQUE INDEX users_secret ON users USING btree (secret);
CREATE INDEX users_state ON users USING btree (state);
CREATE UNIQUE INDEX users_uniq_lower_email ON users USING btree (lower((email)::text));
CREATE UNIQUE INDEX users_uniq_lower_login ON users USING btree (lower((login)::text));
CREATE UNIQUE INDEX users_validkey ON users USING btree (validkey);
SET search_path = stats, pg_catalog;
CREATE UNIQUE INDEX bandit_treatments_abtest_treatment ON bandit_treatments USING btree (abtest_treatment);
CREATE INDEX clans_daily_stats_clan_id_created_on ON clans_daily_stats USING btree (clan_id, created_on);
CREATE INDEX pageloadtime_created_on ON pageloadtime USING btree (created_on);
CREATE INDEX pageviews_abtest_treatmentnotnull ON pageviews USING btree (abtest_treatment) WHERE (abtest_treatment IS NOT NULL);
CREATE INDEX pageviews_abtest_treatmentnull ON pageviews USING btree (abtest_treatment) WHERE (abtest_treatment IS NULL);
CREATE INDEX pageviews_created_on_abtest_treatment ON pageviews USING btree (created_on, abtest_treatment);
CREATE INDEX pageviews_id_visitor_id ON pageviews USING btree (visitor_id, id);
CREATE INDEX pageviews_portal_id ON pageviews USING btree (portal_id);
CREATE INDEX pageviews_visitor_id ON pageviews USING btree (visitor_id);
CREATE INDEX pageviews_visitor_id_and_tstamps ON pageviews USING btree (visitor_id, created_on);
CREATE INDEX portals_stats_portal_id ON portals USING btree (portal_id);
CREATE UNIQUE INDEX portals_stats_uniq ON portals USING btree (created_on, portal_id);
CREATE INDEX users_daily_stats_user_id_created_on ON users_daily_stats USING btree (user_id, created_on);
CREATE UNIQUE INDEX users_karma_daily_by_portal_uniq ON users_karma_daily_by_portal USING btree (user_id, portal_id, created_on);
SET search_path = public, pg_catalog;
ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id);
ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY bets
    ADD CONSTRAINT bets_winning_bets_option_id_fkey FOREIGN KEY (winning_bets_option_id) REFERENCES bets_options(id) MATCH FULL ON DELETE SET NULL;
ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY blogentries
    ADD CONSTRAINT blogentries_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY clans
    ADD CONSTRAINT clans_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY columns
    ADD CONSTRAINT columns_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY comment_violation_opinions
    ADD CONSTRAINT comment_violation_opinions_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES comments(id);
ALTER TABLE ONLY comment_violation_opinions
    ADD CONSTRAINT comment_violation_opinions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY comments_valorations
    ADD CONSTRAINT comments_valorations_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES comments(id);
ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_participant1_id_fkey FOREIGN KEY (participant1_id) REFERENCES competitions_participants(id);
ALTER TABLE ONLY competitions_matches
    ADD CONSTRAINT competitions_matches_participant2_id_fkey FOREIGN KEY (participant2_id) REFERENCES competitions_participants(id);
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_content_type_id_fkey FOREIGN KEY (content_type_id) REFERENCES content_types(id) MATCH FULL;
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_platform_id_fkey FOREIGN KEY (gaming_platform_id) REFERENCES gaming_platforms(id) MATCH FULL;
ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id) MATCH FULL;
ALTER TABLE ONLY contents_terms
    ADD CONSTRAINT contents_terms_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id) MATCH FULL;
ALTER TABLE ONLY contents
    ADD CONSTRAINT contents_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY coverages
    ADD CONSTRAINT coverages_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY decision_choices
    ADD CONSTRAINT decision_choices_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES decisions(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decision_comments
    ADD CONSTRAINT decision_comments_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES decisions(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decision_comments
    ADD CONSTRAINT decision_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decision_user_choices
    ADD CONSTRAINT decision_user_choices_decision_choice_id_fkey FOREIGN KEY (decision_choice_id) REFERENCES decision_choices(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decision_user_choices
    ADD CONSTRAINT decision_user_choices_decision_id_fkey FOREIGN KEY (decision_id) REFERENCES decisions(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decision_user_choices
    ADD CONSTRAINT decision_user_choices_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decision_user_reputations
    ADD CONSTRAINT decision_user_reputations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY decisions
    ADD CONSTRAINT decisions_final_decision_choice_id_fkey FOREIGN KEY (final_decision_choice_id) REFERENCES decision_choices(id) ON DELETE SET NULL;
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id);
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_map_id_fkey FOREIGN KEY (games_map_id) REFERENCES games_maps(id) MATCH FULL;
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_mode_id_fkey FOREIGN KEY (games_mode_id) REFERENCES games_modes(id) MATCH FULL;
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_games_version_id_fkey FOREIGN KEY (games_version_id) REFERENCES games_versions(id) MATCH FULL;
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY demos
    ADD CONSTRAINT demos_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY downloads
    ADD CONSTRAINT downloads_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY events
    ADD CONSTRAINT events_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY events
    ADD CONSTRAINT events_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(id) MATCH FULL;
ALTER TABLE ONLY coverages
    ADD CONSTRAINT events_news_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY events
    ADD CONSTRAINT events_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES events(id) MATCH FULL;
ALTER TABLE ONLY events
    ADD CONSTRAINT events_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY events
    ADD CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY decisions
    ADD CONSTRAINT final_decision_choice_fk FOREIGN KEY (final_decision_choice_id) REFERENCES decision_choices(id) MATCH FULL ON DELETE SET NULL;
ALTER TABLE ONLY topics
    ADD CONSTRAINT forum_topics_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_approved_by_user_id_fkey FOREIGN KEY (approved_by_user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY funthings
    ADD CONSTRAINT funthings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY gamersmafiageist_codes
    ADD CONSTRAINT gamersmafiageist_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE SET NULL;
ALTER TABLE ONLY games
    ADD CONSTRAINT games_gaming_platform_id_fkey FOREIGN KEY (gaming_platform_id) REFERENCES gaming_platforms(id);
ALTER TABLE ONLY games
    ADD CONSTRAINT games_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES terms(id);
ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES groups_messages(id) MATCH FULL;
ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_root_id_fkey FOREIGN KEY (root_id) REFERENCES groups_messages(id) MATCH FULL;
ALTER TABLE ONLY groups_messages
    ADD CONSTRAINT groups_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY images
    ADD CONSTRAINT images_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY images
    ADD CONSTRAINT images_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY interviews
    ADD CONSTRAINT interviews_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY macropolls_2007_1
    ADD CONSTRAINT macropolls_2007_1_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY macropolls
    ADD CONSTRAINT macropolls_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY news
    ADD CONSTRAINT news_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY news
    ADD CONSTRAINT news_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE ONLY gaming_platforms_users
    ADD CONSTRAINT platforms_users_platform_id_fkey FOREIGN KEY (gaming_platform_id) REFERENCES gaming_platforms(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY gaming_platforms_users
    ADD CONSTRAINT platforms_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY polls
    ADD CONSTRAINT polls_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_image_id_fkey FOREIGN KEY (image_id) REFERENCES images(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_images_category_id_fkey FOREIGN KEY (images_category_id) REFERENCES images_categories(id) MATCH FULL;
ALTER TABLE ONLY potds
    ADD CONSTRAINT potds_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_accepted_answer_comment_id_fkey FOREIGN KEY (accepted_answer_comment_id) REFERENCES comments(id);
ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_answer_selected_by_user_id_fkey FOREIGN KEY (answer_selected_by_user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id) MATCH FULL;
ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id);
ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id) MATCH FULL;
ALTER TABLE ONLY recruitment_ads
    ADD CONSTRAINT recruitment_ads_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY refered_hits
    ADD CONSTRAINT refered_hits_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT resurrected_by_user_idfk FOREIGN KEY (resurrected_by_user_id) REFERENCES users(id);
ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY skins_files
    ADD CONSTRAINT skins_files_skin_id_fkey FOREIGN KEY (skin_id) REFERENCES skins(id) MATCH FULL;
ALTER TABLE ONLY staff_candidate_votes
    ADD CONSTRAINT staff_candidate_votes_staff_candidate_id_fkey FOREIGN KEY (staff_candidate_id) REFERENCES staff_candidates(id) MATCH FULL;
ALTER TABLE ONLY staff_candidate_votes
    ADD CONSTRAINT staff_candidate_votes_staff_position_id_fkey FOREIGN KEY (staff_position_id) REFERENCES staff_positions(id) MATCH FULL;
ALTER TABLE ONLY staff_candidate_votes
    ADD CONSTRAINT staff_candidate_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY staff_candidates
    ADD CONSTRAINT staff_candidates_staff_position_id_fkey FOREIGN KEY (staff_position_id) REFERENCES staff_positions(id) MATCH FULL;
ALTER TABLE ONLY staff_candidates
    ADD CONSTRAINT staff_candidates_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL;
ALTER TABLE ONLY staff_positions
    ADD CONSTRAINT staff_positions_staff_type_id_fkey FOREIGN KEY (staff_type_id) REFERENCES staff_types(id) MATCH FULL;
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_bazar_district_id_fkey FOREIGN KEY (bazar_district_id) REFERENCES bazar_districts(id) MATCH FULL;
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_game_id_fkey FOREIGN KEY (game_id) REFERENCES games(id) MATCH FULL;
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_last_updated_item_id_fkey FOREIGN KEY (last_updated_item_id) REFERENCES contents(id);
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_parent_term_id_fkey FOREIGN KEY (parent_id) REFERENCES terms(id) MATCH FULL;
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_platform_id_fkey FOREIGN KEY (gaming_platform_id) REFERENCES gaming_platforms(id) MATCH FULL;
ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_root_id_fkey FOREIGN KEY (root_id) REFERENCES terms(id) MATCH FULL;
ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES clans(id) MATCH FULL;
ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY tutorials
    ADD CONSTRAINT tutorials_unique_content_id_fkey FOREIGN KEY (unique_content_id) REFERENCES contents(id);
ALTER TABLE ONLY user_interests
    ADD CONSTRAINT user_interests_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) MATCH FULL ON DELETE CASCADE;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_avatar_id_fkey FOREIGN KEY (avatar_id) REFERENCES avatars(id) MATCH FULL ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_comments_valorations_type_id_fkey FOREIGN KEY (comments_valorations_type_id) REFERENCES comments_valorations_types(id);
ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_content_id_fkey FOREIGN KEY (content_id) REFERENCES contents(id);
ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_term_id_fkey FOREIGN KEY (term_id) REFERENCES terms(id);
ALTER TABLE ONLY users_contents_tags
    ADD CONSTRAINT users_contents_tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY users
    ADD CONSTRAINT users_faction_id_fkey FOREIGN KEY (faction_id) REFERENCES factions(id) MATCH FULL ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey1 FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_clan_id_fkey2 FOREIGN KEY (last_clan_id) REFERENCES clans(id) ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey1 FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_last_competition_id_fkey2 FOREIGN KEY (last_competition_id) REFERENCES competitions(id) ON DELETE SET NULL;
ALTER TABLE ONLY users
    ADD CONSTRAINT users_referer_user_id_fkey FOREIGN KEY (referer_user_id) REFERENCES users(id) MATCH FULL;
SET search_path = stats, pg_catalog;
ALTER TABLE ONLY clans_daily_stats
    ADD CONSTRAINT clans_daily_stats_clan_id_fkey FOREIGN KEY (clan_id) REFERENCES public.clans(id) MATCH FULL;
ALTER TABLE ONLY users_daily_stats
    ADD CONSTRAINT users_daily_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) MATCH FULL;
