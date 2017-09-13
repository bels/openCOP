package Opencop;
use Mojo::Base 'Mojolicious';

use Mojo::Pg;
use Opencop::Model::Audit;
use Opencop::Model::Account;
use Opencop::Model::Auth;
use Opencop::Model::Ticket;
use Opencop::Model::Core;
use Opencop::Model::Reports;
use Opencop::Model::Queues;

# This method will run once at server start
sub startup {
  my $self = shift;
  
  #### CHANGE THIS FOR YOUR DEPLOYMENT #####
  
  $self->secrets(['OpenCOP!!','Helpdesk1234','ToManyProblems1!']);
  $self->session(expiration => 28800);
  #####

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  $self->plugin('Config');
  
  $self->helper(pg => sub { state $pg = Mojo::Pg->new( shift->config('pg'))});
  $self->pg->search_path(['ticket','opencop','auth','audit','public']);
  $self->helper(audit => sub { 
  	my $app = shift;
	state $audit = Opencop::Model::Audit->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 :  0)
  });
  $self->helper(account => sub {
  	my $app = shift;
  	state $account = Opencop::Model::Account->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  $self->helper(auth => sub {
  	my $app = shift;
  	state $auth = Opencop::Model::Auth->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  $self->helper(ticket => sub {
  	my $app = shift;
  	state $ticket = Opencop::Model::Ticket->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  $self->helper(core => sub {
  	my $app = shift;
  	state $core = Opencop::Model::Core->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  $self->helper(reports => sub {
  	my $app = shift;
  	state $reports = Opencop::Model::Reports->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  $self->helper(queue => sub {
    my $app = shift;
    state $queue = Opencop::Model::Queues->new(pg => $app->pg, debug => $app->app->mode eq 'development' ? 1 : 0);
  });
  
  $self->helper(set_selected => sub{
  	#must pass in an array ref containing a hashref in each element
  	my ($app,$list,$index_to_match,$selected) = @_;

  	for my $i (0 .. scalar @{$list} - 1){
  		if($list->[$i][$index_to_match] eq $selected){
  			push(@{$list->[$i]},selected => 'selected');
  		}
  	}
  	
  	return $list;
  });
  
  $self->helper(meta_keywords => sub {
  	
  });
  
  $self->helper(meta_description => sub{
  	
  });
  $self->helper(has_permission => sub{
	my ($self,$permission,$object) = @_;
	#i don't like this.  I would prefer to not have to pass in the user id but the backend can't handle checking permissions without it yet
	return $self->auth->hasPermission($self->session->{'user_id'},$permission,$object); 
  });

  $self->hook(before_dispatch => sub{
	my $self = shift;
	$self->audit->page_visit($self->tx);
  });
  # Router
  my $r = $self->routes;

  # Normal route to controller 
  $r->get('/')->to('core#index')->name('index');
  $r->get('/client')->to('client#index')->name('customer_index');
  $r->post('/auth')->to('auth#authenticate')->name('auth');
  my $authed = $r->under()->to('auth#check_session');
  $authed->get('/dashboard')->to('core#dashboard')->name('dashboard'); #Reroutes people to the right dashboard depending if they are a customer or technician
  $authed->get('/technician/dashboard')->to('technician#dashboard')->name('technician_dashboard');
  $authed->get('/client/dashboard')->to('client#dashboard')->name('client_dashboard');
  $authed->get('/user/preferences')->to('user#preferences')->name('user_preferences');
  $authed->post('/user/password/set')->to('user#set_password')->name('set_password');
  $authed->get('/ticket/new')->to('ticket#new_form')->name('new_ticket_form');
  $authed->post('/ticket/new')->to('ticket#new_ticket')->name('new_ticket');
  $authed->post('/ticket/update/:ticket_id')->to('ticket#update')->name('update_ticket');
  $authed->get('/ticket/queue/all')->to('ticket#all_queues')->name('view_all_ticket_queues');
  $authed->get('/ticket/client/queue')->to('ticket#client_queue')->name('client_queue');
  $authed->get('/ticket/queue/:queue')->to('ticket#queue')->name('view_ticket_queue');
  $authed->post('/ticket/troubleshooting/add')->to('ticket#add_troubleshooting')->name('add_troubleshooting');
  $authed->post('/ticket/delete/:ticket_id')->to('ticket#delete')->name('delete_ticket');
  $authed->get('/ticket/:ticket_id')->to('ticket#view_ticket')->name('view_ticket');
  $authed->get('/work-order/new')->to('workorder#new_form')->name('new_work_order_form');
  $authed->post('/work-order')->to('workorder#new')->name('new_work_order');
  $authed->get('/work-order/queue/all')->to('workorder#all_work_orders')->name('view_all_work_orders');
  $authed->get('/work-order/queue/:work_order_queue')->to('workorder#queue')->name('view_work_order_queue');
  $authed->post('/work-order/update/:work_order_number')->to('workorder#update')->name('update_work_order');
  $authed->get('/work-order/:work_order_number')->to('workorder#view_work_order')->name('view_work_order');
  $authed->get('/report-builder')->to('reports#report_builder_form')->name('report_builder_form');
  $authed->post('/report-builder')->to('reports#save_report')->name('save_report');
  $authed->get('/reports')->to('reports#view_all')->name('view_all_reports');
  $authed->get('/report/:report')->to('reports#view')->name('view_report');
  $authed->post('/report/:report')->to('reports#retrieve_report')->name('retrieve_report');
  $authed->get('/inventory/add')->to('inventory#add_form')->name('add_inventory_form');
  $authed->post('/inventory/add')->to('inventory#add')->name('add_inventory');
  $authed->get('/inventory')->to('inventory#view_all')->name('view_all_inventory');
  $authed->get('/inventory/configure')->to('inventory#configure_form')->name('configure_inventory_form');
  $authed->post('/inventory/configure')->to('inventory#configure')->name('configure_inventory');
  $authed->get('/inventory/company/:company')->to('inventory#view_company')->name('view_company_inventory');
  $authed->get('/inventory/:asset_id')->to('inventory#view')->name('view_asset');
  $authed->get('/admin/customer/list')->to('admin#list')->name('list_customers');
  $authed->post('/admin/customer/new')->to('admin#new_customer')->name('new_customer');
  $authed->post('/admin/customer/edit')->to('admin#edit_customer')->name('edit_customer');
  $authed->get('/admin/customer/settings')->to('admin#customer_settings')->name('admin_customer_settings');
  $authed->post('/admin/customer/delete')->to('admin#delete_customer')->name('delete_customer');
  $authed->post('/admin/customer/site/new')->to('admin#new_site')->name('new_site');
  $authed->post('/admin/customer/site/edit')->to('admin#edit_site')->name('edit_site');
  $authed->post('/admin/customer/site/delete')->to('admin#delete_site')->name('delete_site');
  $authed->get('/admin/customer/:customer')->to('admin#view_customer')->name('view_customer');
  $authed->get('/admin/work_orders')->to('admin#work_orders')->name('admin_work_orders');
  $authed->get('/admin/users')->to('admin#view_users')->name('view_users');
  $authed->post('/admin/new/user')->to('admin#new_user')->name('new_user');
  $authed->post('/admin/edit/user')->to('admin#edit_user')->name('edit_user');
  $authed->get('/admin/settings/general')->to('admin#general_settings')->name('general_settings');
  $authed->post('/admin/settings/general')->to('admin#save_general_settings')->name('save_general_settings');
  $authed->get('/admin/groups')->to('admin#view_groups')->name('view_groups');
  $authed->get('/admin/new/group')->to('admin#new_group_form')->name('new_group_form');
  $authed->post('/admin/new/group')->to('admin#new_group')->name('new_group');
  $authed->post('/admin/edit/group')->to('admin#edit_group')->name('edit_group');
  $authed->get('/admin')->to('admin#dashboard')->name('admin_dashboard');
  $authed->get('/permissions')->to('admin#view_permissions')->name('view_permissions');
  $authed->get('/permissions/new')->to('admin#new_permission_form')->name('new_permission_form');
  $authed->post('/permissions/new')->to('admin#new_permission')->name('new_permission');
  $authed->post('/permissions/edit')->to('admin#edit_permission')->name('edit_permission');
  $authed->get('/logout')->to('auth#logout')->name('logout');
}

1;
