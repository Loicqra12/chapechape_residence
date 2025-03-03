import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/message/message_bloc.dart';
import '../../../core/models/message/message.dart';
import '../../../core/models/user/user.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../widgets/layout/screen_app_bars.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    
    // Charger les messages au démarrage
    context.read<MessageBloc>().add(LoadMessages(userId: 'partner_1'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ScreenAppBars.getMessagesAppBar(context),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Clients'),
                  Tab(text: 'Support'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ConversationsList(type: 'client'),
                _ConversationsList(type: 'support'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _ConversationsList extends StatelessWidget {
  final String type;

  const _ConversationsList({required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, state) {
        if (state is MessageLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MessageError) {
          return Center(child: Text(state.message));
        }

        if (state is MessagesLoaded) {
          final conversations = state.messages
              .where((message) => type == 'client' 
                  ? message.messageType != 'support'
                  : message.messageType == 'support')
              .toList();

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'client' ? Icons.people_outline : Icons.support_agent_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == 'client'
                        ? 'Aucune conversation avec des clients'
                        : 'Aucune conversation avec le support',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationTile(conversation: conversation);
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Message conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          'N', // TODO: Get from user service
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        'Nom du contact', // TODO: Get from user service
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        conversation.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeago.format(conversation.timestamp, locale: 'fr'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!conversation.isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Nouveau',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to chat screen
      },
    );
  }
}
