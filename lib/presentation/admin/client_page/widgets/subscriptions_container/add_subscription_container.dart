// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../core/presentation/components/inputs/animation/splash_animation.dart';
import '../../../../../core/utils/domain_error.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/subscription/client_subscription.dart';
import '../../../../../domain/entities/subscription/subscription.dart';
import '../../../../../domain/repositories/subscription_repository.dart';
import '../../../../core/cubit/auth/auth_cubit.dart';
import '../../client_page.dart';

class AddSubscriptionContainer extends StatefulWidget {
  const AddSubscriptionContainer({
    super.key,
    required this.clubPartitions, 
    required this.client,
  });

  final List<ClubPartition>? clubPartitions;
  final Client client;
  
  @override
  State<AddSubscriptionContainer> createState() => _AddSubscriptionContainerState();
}

class _AddSubscriptionContainerState extends State<AddSubscriptionContainer> {

  Subscription? selectedSubscription;
  bool isLoading = false;
  bool isConfirmed = false; 
  final subscriptionRepository = sl<SubscriptionRepository>();



  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    if(isConfirmed){

      return SplashAnimation(
        width: 300, 
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 50).animate().fadeIn(delay: const Duration(milliseconds: 400)),
            Text("Subscripcion confirmada", style: textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onPrimary, ),).animate().fadeIn(delay: const Duration(milliseconds: 450))
          ],
        )
      );
    }

    if(selectedSubscription != null) {
      return buildConfirmation(textTheme, context).animate().fadeIn().moveY();
    }

    return buildSubscriptionSelection(context);
  }

  SizedBox buildSubscriptionSelection(BuildContext context) {
    return SizedBox(
    height: 200,
    child: ListView(
      children: [
        ListTile(title: Text("Nueva subscripcion", style: Theme.of(context).textTheme.titleLarge)),
        Divider(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface,
          ), 
        ...widget.clubPartitions!.expand((clubPartition){
        return clubPartition.subscriptions!.map((subscription){
            return ListTile(
              trailing: Text("\$${subscription.getCurrentPrice()!.price}", style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(clubPartition.clubType!.name),
              title: Text(subscription.name, style: Theme.of(context).textTheme.bodyLarge),
              onTap: (){
                setState(() {
                  selectedSubscription = subscription;
                });
              },
            );
          }).toList();
      },
    )]
  ),
  );
  }

  Container buildConfirmation(TextTheme textTheme, BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirmar subscripcion", style: textTheme.headlineSmall,),
            const SizedBox(height: 12,),
            RichText(
              text: TextSpan(
                
                children: [
                  TextSpan(text: "Confirmar subscripcion a ", style: textTheme.bodyMedium),
                  TextSpan(text: widget.client.person!.fullName, style: textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.primary)), 
                  TextSpan(text: " en subscripcion ", style: textTheme.bodyMedium),
                  TextSpan(text: selectedSubscription!.name, style: textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.primary)), 

                ]
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: (){
                    setState(() {
                      selectedSubscription = null;
                    });
                  }, 
                  child: const Text("Cancelar")),
                
                if(isLoading)
                  const SizedBox(
                    width: 100,
                    child: Center(
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                else
                SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () async { 
                      setState(() {
                        isLoading = true;
                      });
                      
                      final response = await subscriptionRepository.subscribeClient({
                        "client_id":int.parse(widget.client.clientId!),
                        "subscription_id":selectedSubscription!.subscriptionId,
                        "created_by_admin":sl<AuthCubit>().state.userCredential!.admin!.adminId
                      }, int.parse(widget.client.clientId!));

                      final result = switch (response) {
                        Left(:final failure) => failure,
                        Right(:final value) => value,
                      };

                      if(result is DomainError){
                        return setState(() {
                          isLoading = false;
                        });
                      }

                     if(result is ClientSubscription){

                        final clientInherited = ClientInherited.of(context);

                        clientInherited?.updateClient(widget.client.copyWith(clientSubscriptions: [result, ...widget.client.clientSubscriptions ?? []]));

                        return setState(() {
                          isConfirmed = true;
                          isLoading = false;
                        });
                      }
                  
                    }, 
                    child: const Text("Confirmar")),
                ),
              ],
            )
          ],
        ),
    );
  }
}