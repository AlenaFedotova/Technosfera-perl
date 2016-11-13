use utf8;
package Local::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Local::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 karma

  data_type: 'double precision'
  is_nullable: 0

=head2 rating

  data_type: 'double precision'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "username",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "karma",
  { data_type => "double precision", is_nullable => 0 },
  "rating",
  { data_type => "double precision", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->set_primary_key("username");

=head1 RELATIONS

=head2 comments

Type: has_many

Related object: L<Local::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "Local::Schema::Result::Comment",
  { "foreign.commentor" => "self.username" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 posts_2s

Type: has_many

Related object: L<Local::Schema::Result::Post>

=cut

__PACKAGE__->has_many(
  "posts_2s",
  "Local::Schema::Result::Post",
  { "foreign.author" => "self.username" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 posts

Type: many_to_many

Composing rels: L</comments> -> post

=cut

__PACKAGE__->many_to_many("posts", "comments", "post");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2016-11-13 18:17:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5LzHo0z1u9IseYDPHzFR7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
