----------------------------------------------------------------------
-- Prototype of new request schema for Oct2012 CodeFest

create sequence seq_req2_type;

/* Type of request */
create table t_req2_type
  (id			integer		not null,
   name			varchar(100)	not null,
   --
   constraint pk_req2_type
     primary key (id),
   --
   constraint uk_req2_type_name
     unique (name)
);
/* Fixed data for types */
insert into t_req2_type (id, name)
  values (seq_req2_type.nextval, 'xfer');
insert into t_req2_type (id, name)
   values (seq_req2_type.nextval, 'delete');
insert into t_req2_type (id, name)
   values (seq_req2_type.nextval, 'invalidation');
insert into t_req2_type (id, name)
   values (seq_req2_type.nextval, 'consistency');

-- 
/* Table t_req2_state of states in the request state machine */

create sequence seq_req2_state;

create table t_req2_state
  (id			integer		not null,
   name			varchar(100)	not null,
   --
   constraint pk_req2_state
     primary key (id),
   --
   constraint uk_req2_state_name
     unique (name)
);

/* Fixed data for states */
insert into t_req2_state (id, name)
  values (seq_req2_state.nextval, 'created');
insert into t_req2_state (id, name)
   values (seq_req2_state.nextval, 'suspended');
insert into t_req2_state (id, name)
   values (seq_req2_state.nextval, 'approved');
insert into t_req2_state (id, name)
   values (seq_req2_state.nextval, 'denied');
insert into t_req2_state (id, name)
   values (seq_req2_state.nextval, 'cancelled');
insert into t_req2_state (id, name)
   values (seq_req2_state.nextval, 'done');

-- 
/* Table t_req2_actions of possible user actions on the requests 
   The code should trigger transitions to the desired_state if appropriate
   NOTE: for 'suspend', 'deny', 'cancel' the appropriate transition is
	 triggered immediately, while for 'approve' actions the transition
	 is triggered only if all persons in the approval list have also approved
*/

create sequence seq_req2_action;

create table t_req2_action
  (id			integer		not null,
   name			varchar(100)	not null,
   desired_state	integer		not null,
   --
   constraint pk_req2_action
     primary key (id),
   --
   constraint fk_req2_action_state
     foreign key (desired_state) references t_req2_state (id),
   --
   constraint uk_req2_action_name
     unique (name)
);

create index ix_req2_action_state
  on t_req2_action (desired_state);

/* Fixed data for actions */
insert into t_req2_action (id, name, desired_state)
   select seq_req2_action.nextval, 'suspend',
	   id from t_req2_state where name='suspended';
insert into t_req2_action (id, name, desired_state)
   select seq_req2_action.nextval, 'approve',
	   id from t_req2_state where name='approved';
insert into t_req2_action (id, name, desired_state)
   select seq_req2_action.nextval, 'cancel',
	   id from t_req2_state where name='cancelled';
insert into t_req2_action (id, name, desired_state)
   select seq_req2_action.nextval, 'deny',
	   id from t_req2_state where name='denied';

/* Main request table */

create sequence seq_req2_request;

create table t_req2_request
  (id			integer		not null,
   type			integer		not null,
   state		integer		not null,
   created_by		integer		not null,  -- who created the request
   time_create		float		not null,
   time_end		float			,  -- time when the request reached a terminal state, after which the request can be cleaned up
   --
   constraint pk_req2_request
     primary key (id),
   --
   constraint fk_req2_request_type
     foreign key (type) references t_req2_type (id),
   --
   constraint fk_req2_request_state
     foreign key (state) references t_req2_state (id),
   --
   constraint fk_req2_request_created_by
     foreign key (created_by) references t_adm_client (id)
);

create index ix_req2_request_by
  on t_req2_request (created_by);

create index ix_req2_request_type
  on t_req2_request (type);

create index ix_req2_request_state
  on t_req2_request (state);

--

/* t_req2_transition table of allowed state changes in the
   request finite state machine */

create sequence seq_req2_transition;

create table t_req2_transition
  (id			integer		not null,
   from_state		integer		not null,
   to_state		integer		not null,
   --
   constraint pk_req2_transition
     primary key (id),
   --
   constraint uk_req2_transition_from_to
     unique (from_state, to_state),
   --
   constraint fk_req2_transition_from
     foreign key (from_state) references t_req2_state (id),
   --
   constraint fk_req2_transition_to
     foreign key (to_state) references t_req2_state (id)
);   

create index ix_req2_transition_from
  on t_req2_transition (from_state);

create index ix_req2_transition_to
  on t_req2_transition (to_state);

/* Add some state transitions */

insert into t_req2_transition (id, from_state, to_state)
  select seq_req2_transition.nextval, rf.id, rt.id
	from t_req2_state rf, t_req2_state rt
	where rf.name='created' and rt.name='approved';
insert into t_req2_transition (id, from_state, to_state)
  select seq_req2_transition.nextval, rf.id, rt.id
	from t_req2_state rf, t_req2_state rt
	where rf.name='created' and rt.name='denied';
insert into t_req2_transition (id, from_state, to_state)
  select seq_req2_transition.nextval, rf.id, rt.id
	from t_req2_state rf, t_req2_state rt
	where rf.name='created' and rt.name='suspended';
insert into t_req2_transition (id, from_state, to_state)
  select seq_req2_transition.nextval, rf.id, rt.id
	from t_req2_state rf, t_req2_state rt
	where rf.name='approved' and rt.name='cancelled';
insert into t_req2_transition (id, from_state, to_state)
  select seq_req2_transition.nextval, rf.id, rt.id
	from t_req2_state rf, t_req2_state rt
	where rf.name='approved' and rt.name='done';

/* t_req2_rule table of allowed state changes for each request type in the
   request finite state machine */

create sequence seq_req2_rule;

create table t_req2_rule
  (id			integer		not null,
   type			integer		not null,
   transition		integer		not null,
   --
   constraint pk_req2_rule
     primary key (id),
   --
   constraint uk_req2_rule
     unique (type, transition),
   --
   constraint fk_req2_rule_type
     foreign key (type) references t_req2_type (id),
   --
   constraint fk_req2_transition
     foreign key (transition) references t_req2_transition (id)
);   

create index ix_req2_rule_type
  on t_req2_rule (type);

create index ix_req2_rule_transition
  on t_req2_rule (transition);

/* Add some transition rules */

insert into t_req2_rule (id, type, transition)
  select seq_req2_rule.nextval, rtp.id, rt.id
	from t_req2_type rtp, t_req2_transition rt
	join t_req2_state rtf on rt.from_state=rtf.id
	join t_req2_state rtt on rt.to_state=rtt.id
	where rtp.name='xfer' and
	rtf.name='created' and rtt.name='approved';
insert into t_req2_rule (id, type, transition)
  select seq_req2_rule.nextval, rtp.id, rt.id
	from t_req2_type rtp, t_req2_transition rt
	join t_req2_state rtf on rt.from_state=rtf.id
	join t_req2_state rtt on rt.to_state=rtt.id
	where rtp.name='delete' and
	rtf.name='created' and rtt.name='denied';
insert into t_req2_rule (id, type, transition)
  select seq_req2_rule.nextval, rtp.id, rt.id
	from t_req2_type rtp, t_req2_transition rt
	join t_req2_state rtf on rt.from_state=rtf.id
	join t_req2_state rtt on rt.to_state=rtt.id
	where rtp.name='invalidation' and
	rtf.name='approved' and rtt.name='cancelled';

/* t_req2_permission table of allowed state changes per role and domain */

create sequence seq_req2_permission;

create table t_req2_permission
  (id			integer		not null,
   rule			integer		not null,
   role			integer		not null,
   --
   constraint pk_req2_permission
     primary key (id),
   --
   constraint uk_req2_permission
     unique (rule, role),
   --
   constraint fk_req2_permission_rule
     foreign key (rule) references t_req2_rule (id),
   --
   constraint fk_req2_permission_role
     foreign key (role) references t_adm2_role (id)
);   

create index ix_req2_permission_rule
  on t_req2_permission (rule);

create index ix_req2_permission_role
  on t_req2_permission (role);

/* Add some transition rules */

insert into t_req2_permission (id, rule, role)
  select seq_req2_permission.nextval, rr.id, ar.id
	from t_adm2_role ar, t_req2_rule rr
	join t_req2_transition rt on rt.id=rr.transition
	join t_req2_type rtp on rtp.id=rr.type
	join t_req2_state rtf on rt.from_state=rtf.id
	join t_req2_state rtt on rt.to_state=rtt.id
	where rtp.name='xfer' and
	rtf.name='created' and rtt.name='approved'
	and ar.role='Data Manager' and ar.domain='group';

-------------------------------------------------------
/* Table to log arbitrary comments by users */
/* Note "comment" is an Oracle reserved word */


create sequence seq_req2_comments;

create table t_req2_comments
  (id			integer		not null,
   request		integer		not null,
   comments_by		integer		not null,
   comments		varchar (4000)	not null,
   time_comments	integer		not null,
   --
   constraint pk_req2_comments
     primary key (id),
   --
   constraint fk_req2_comments_request
     foreign key (request) references t_req_request (id)
     on delete cascade,
   --
   constraint fk_req2_comments_by
     foreign key (comments_by) references t_adm_client (id)
);

create index ix_req2_comments_request
  on t_req2_comments (request);
create index ix_req2_comments_by
  on t_req2_comments (comments_by);

--------------------------------------------------------

/* Request state change action log
   The code should trigger transitions to the desired_state if appropriate
   NOTE: for 'suspended', 'denied', 'cancelled' desired_state, the appropriate transition is
	 triggered immediately, while for the 'approved' desired_state the transition
	 is triggered if and only if all persons in the approval list have approved
   FIXME: need to create comments table before defining column here...
*/


create sequence seq_req2_action_log;

create table t_req2_action_log
  (id			integer		not null,
   request		integer		not null,
   desired_state	integer		not null, -- new desired state for the request
   decided_by		integer		not null, -- who decided
   time_decided		float		not null,
   transition		integer			, -- transition triggered by the action, if any. See notes for details.
   comments		integer			, -- link to the comments logged at action time, if any
   --
   constraint pk_req2_action_log
     primary key (id),
   --
   constraint fk_req2_action_log_request
     foreign key (request) references t_req2_request (id),
   --
   constraint fk_req2_action_log_state
     foreign key (desired_state) references t_req2_state (id),
   --
   constraint fk_req2_action_log_by
     foreign key (decided_by) references t_adm_client (id),
   --
   constraint fk_req2_action_log_transition
     foreign key (transition) references t_req2_transition (id),
   --
   constraint fk_req2_action_log_comments
     foreign key (comments) references t_req2_comments (id)
     on delete set null
);

create index ix_req2_action_log_request
  on t_req2_action_log (request);
create index ix_req2_action_log_state
  on t_req2_action_log (desired_state);
create index ix_req2_action_log_by
  on t_req2_action_log (decided_by);
create index ix_req2_action_log_transition
  on t_req2_action_log (transition);
create index ix_req2_action_log_comments
  on t_req2_action_log (comments);

